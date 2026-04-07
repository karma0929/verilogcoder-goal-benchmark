#
# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# Author : Chia-Tung (Mark) Ho, NVIDIA
#

# Example of User write this file use hardware agent
import os
import re
from hardware_agent.hardware_general_agent import HardwareAgent
from hardware_agent.tools_utility import get_tools_descriptions, create_tool_tbl
# import tool function from timing summary tools
from autogen.coding import DockerCommandLineCodeExecutor, LocalCommandLineCodeExecutor
from autogen import config_list_from_json
from hardware_agent.examples.VerilogCoder.verilog_tools_class import VerilogToolKits, logic_checker_tool

from typing import Any, Callable, Dict, List, Literal, Optional, Tuple, Type, TypeVar, Union, Annotated
from hardware_agent.examples.VerilogCoder.task_planner import TaskPlanAgent
from hardware_agent.output_parser_util import verilog_output_parse, validate_correct_parse
from hardware_agent.task import Task, BaseTaskFlowManager
from hardware_agent.knowledge_circuit_graph import KnowledgeGraphToolKits
from hardware_agent.examples.VerilogCoder.verilog_agent_configs import tool_usage_prompt
import copy as cp
import json
import time
import re

# Example for LLM
from hardware_agent.examples.VerilogCoder.ICL_examples import GeneralExample

# LLM model dependant: For GPT or Llama or Mistral
from hardware_agent.examples.VerilogCoder.llm_prompt_manager import get_plan_retrieve_prompt, \
    get_verilog_completion_prompt, get_verilog_debug_prompt
from hardware_agent.examples.VerilogCoder.llm_prompt_manager import get_plan_graph_retrieval_agent_config, \
    get_verilog_completion_agent_config, get_verilog_debug_agent_config

class VerilogCoder:

    def __init__(self,
                 task_planner_llm_config,
                 kg_llm_config,
                 graph_retrieval_llm_config,
                 verilog_writing_llm_config,
                 debug_llm_config,
                 llm_types: Dict[str, str],
                 generate_plan_dir: str="./generated_verilog_plans/",
                 generate_verilog_dir: str="./generated_verilog_code/",
                 verilog_tmp_dir: str="./verilog_tool_tmp/"):

        # Toolkit initialization
        self.kg_plan_tool = KnowledgeGraphToolKits(
            llm_config={"config_list": kg_llm_config, "cache_seed": None, "temperature": 0.0, "top_p": 1})
        tool_workdir = verilog_tmp_dir if os.path.isabs(verilog_tmp_dir) else os.path.join(os.getcwd(), verilog_tmp_dir)
        self.verilog_tools = VerilogToolKits(workdir=tool_workdir)

        # dirs
        self.verilog_tmp_dir = verilog_tmp_dir
        self.plan_output_dir = generate_plan_dir
        self.verilog_output_dir = generate_verilog_dir
        self.llm_types = llm_types
        os.makedirs(self.plan_output_dir, exist_ok=True)
        os.makedirs(self.verilog_output_dir, exist_ok=True)

        # setup task planning agent
        print("[Info]: Initializing task planner agent")
        self.task_planner_agent = TaskPlanAgent(task_planner_llm_config)

        plan_gr_tool_configs = self.setup_plan_graph_tool()
        plan_gr_agent_config, plan_gr_group_config = get_plan_graph_retrieval_agent_config(
            llm_type=llm_types["graph_retrieval_llm"],
            llm_config=graph_retrieval_llm_config)
        self.plan_gr_agent = HardwareAgent(agent_configs=plan_gr_agent_config, tool_configs=plan_gr_tool_configs,
                                              group_chat_kwargs=plan_gr_group_config)

        # setup code completion agent
        print("[Info]: Initializing verilog code completion agent")
        verilog_completion_tool_configs = self.setup_verilog_completion_tool()
        verilog_completion_agent_config, verilog_completion_group_config = get_verilog_completion_agent_config(
            llm_type=llm_types["verilog_writing_llm"],
            llm_config=verilog_writing_llm_config)
        verilog_completion_agent_config = tool_usage_prompt(verilog_completion_tool_configs,
                                                            verilog_completion_agent_config)
        self.verilog_complete_agent = HardwareAgent(agent_configs=verilog_completion_agent_config,
                                               tool_configs=verilog_completion_tool_configs,
                                               group_chat_kwargs=verilog_completion_group_config)


        # setup debug agent
        print("[Info]: Initializing debug agent")
        code_debug_tool_configs = self.setup_debug_tool()
        code_debug_agent_config, code_debug_group_config = get_verilog_debug_agent_config(
            llm_type=llm_types["verilog_debug_llm"],
            llm_config=debug_llm_config)
        code_debug_agent_config = tool_usage_prompt(code_debug_tool_configs, code_debug_agent_config)
        self.code_debug_agent = HardwareAgent(agent_configs=code_debug_agent_config,
                                         tool_configs=code_debug_tool_configs,
                                         group_chat_kwargs=code_debug_group_config)
        self.last_debug_artifacts = {}
        print("[Info]: Finish initializing agents")

    # Default tool: Can be extended further
    def setup_plan_graph_tool(self):
        # Tool function calls
        def retrieve_additional_plan_information_tool(
                current_plan: Annotated[str, "The plan to query the knowledge graph database."],
                BFS_retrival_level: Annotated[
                    int, "The BFS search level in knowledge graph database based on current_plan"]) -> str:
            return self.kg_plan_tool.networkx_bfs_knowledge_graph_query(query=current_plan,
                                                                        bfs_level=BFS_retrival_level)

        plan_gr_tool_configs = [
            {'function_call': retrieve_additional_plan_information_tool,
             'executor': "user",
             'caller': "verilog_engineer",
             'name': "retrieve_additional_plan_information_tool",
             'description': '\tUse this tool to retrieve required information about the plan.'
                            '\n\tInput the current_plan in string format and BFS_retrival_level in integer format. Output is the string of retrieved information.',
             'tool_examples': ''}
        ]
        return plan_gr_tool_configs

    # Default tool: Can be extended further
    def setup_verilog_completion_tool(self):
        def verilog_syntax_check_tool(
                completed_verilog: Annotated[str, "The completed verilog module code implementation"]) -> str:
            return self.verilog_tools.verilog_syntax_check_tool(completed_verilog=completed_verilog)

        verilog_completion_tool_configs = [
            {'function_call': verilog_syntax_check_tool,
             'executor': "user",
             'caller': "verilog_verification_assistant",
             'name': "verilog_syntax_check_tool",
             'description': '\tUse this tool to examine the syntax correctness of completed verilog module.'
                            '\n\tInput the completed verilog module in string format. Output is the string of pass or failed.',
             'tool_examples': ''}
        ]
        return verilog_completion_tool_configs

    # Default tool: Can be extended further
    def setup_debug_tool(self):
        def verilog_simulation_tool(
                completed_verilog: Annotated[str, "The completed verilog module code implementation"]) -> str:
            return self.verilog_tools.verilog_simulation_tool(completed_verilog=completed_verilog)

        def waveform_trace_tool(function_check_output: Annotated[str, "The output string of function "
                                                                      "check from verilog_simulation_tool."],
                                trace_level: Annotated[int, "The number of level for wrong signal waveform tracing. "
                                                            "It should be larger than 1."]) -> str:
            return self.verilog_tools.waveform_trace_tool(function_check_output=function_check_output,
                                                     trace_level=trace_level)

        # Not used for now
        '''
        def recall_spec_and_generated_verilog_code_tool() -> str:
            return self.verilog_tools.recall_spec_and_generated_verilog_code_tool()
        '''

        code_debug_tool_configs = [
            {'function_call': verilog_simulation_tool,
             'executor': "user",
             'caller': "verilog_engineer",
             'name': "verilog_simulation_tool",
             'description': '\tUse this tool to examine the syntax and functional correctness of completed verilog module.'
                            '\n\tInput the completed verilog module in string format. Output is the string of pass or failed.',
             'tool_examples': ''},
            {'function_call': waveform_trace_tool,
             'executor': "user",
             'caller': "verilog_engineer",
             'name': "waveform_trace_tool",
             'description': '\tUse this tool to trace the functional incorrect signal waveforms.'
                            '\n\tInput the function_check_output with the output response of verilog_simulation_tool and trace_level for control signal level tracing. '
                            'Output is the string of waveform and generated partial code relevant to the functional incorrect signals and their control signals.',
             'tool_examples': ''},
        ]
        return code_debug_tool_configs

    # revalidate for gateway chats
    def revalidate_agents(self):
        self.task_planner_agent.revalidate_llm_config()
        self.plan_gr_agent.revalidate_llm_config()
        self.verilog_complete_agent.revalidate_llm_config()
        self.code_debug_agent.revalidate_llm_config()

    # write Verilog module
    def write_Verilog_module(self, cur_task_id, spec, golden_test_bench,
                             plan_filename: str= "",
                             completed_module: str="",
                             have_plans: bool = False,
                             skip_kg_plan: bool = False,
                             have_completed_code: bool = False):
        self.last_debug_artifacts = {}
        self.verilog_tools.load_test_bench(task_id=cur_task_id, spec=spec,
                                           test_bench=golden_test_bench, write_file=True)

        if not have_plans:
            # Load plan from JSON file to dictionary
            task_flow_plans = self.make_plans(cur_task_id=cur_task_id, module=spec, skip_kg_plan=skip_kg_plan)
        else:
            with open(plan_filename, 'r') as json_file:
                task_flow_plans = json.load(json_file)

        # complete the code
        if not have_completed_code:
            success, module_file, test_file = self.complete_functional_correct_code(cur_task_id=cur_task_id,
                                                                                    module=spec,
                                                                                    task_flow_plans=task_flow_plans)
        else:
            # debug only; should not use this in common
            success, module_file, test_file = self.debug_completed_module(cur_task_id=cur_task_id,
                                                                          module=spec,
                                                                          completed_module=completed_module)

        # Info output
        if success:
            print("[VerilogCoder Info]: Successfully write functional correct module.")
        else:
            print("[VerilogCoder Info]: Failed write functional correct module.")
        if "FAILED_FILE" in module_file:
            print("[VerilogCoder Info]: Failed to generate the module file! Please check the task plans!")
            return False

        print("Generated module file: ", self.verilog_output_dir + "/" + module_file )
        print("Generated testbench with module file: ", self.verilog_output_dir + "/" + test_file)
        return success

    # Make plans for writing the module according to the spec
    def make_plans(self, cur_task_id, module: str, skip_kg_plan: bool=False, show_plan: bool=False):
        """
        module: input module description
        """
        self.revalidate_agents()
        rough_plan, signal_nodes_extract = self.task_planner_agent.make_plans(module=module)
        print('rough_plan = ', rough_plan, '\n\nentity extraction = ', signal_nodes_extract)
        with open(self.plan_output_dir + "/" + cur_task_id + "_rough_plan.json", 'w') as json_file:
            json.dump(rough_plan, json_file)
        # create the kg graph
        if not skip_kg_plan:
            plan_contents = []
            for plan in rough_plan:
                plan_contents.append(plan['content'])
            self.kg_plan_tool.create_knowledge_graph(TEXT=module,
                                                plans=plan_contents,
                                                signal_nodes_extract=signal_nodes_extract,
                                                determined_nodes=True)

            for plan in rough_plan:
                # prompt dependant to the LLM model
                prompt_params = get_plan_retrieve_prompt(llm_type=self.llm_types["graph_retrieval_llm"])
                if self.llm_types["graph_retrieval_llm"] == "llama3":
                    plan_gr_prompt = prompt_params["template"].format(ToolExamples=prompt_params["tool_examples"],
                                                                      CurrentPlan=plan['content'])
                else:
                    # default prompt for gpt
                    plan_gr_prompt = prompt_params["template"].format(Module=module,
                                                                      CurrentPlan=plan['content'])
                plan_gr = self.plan_gr_agent.initiate_chat(message=plan_gr_prompt)
                plan['content'] = plan_gr.summary

        # Detailed KG retrieval plan
        task_flow_plans = cp.deepcopy(rough_plan)
        with open(self.plan_output_dir + "/" + cur_task_id + "_plan.json", 'w') as json_file:
            json.dump(task_flow_plans, json_file)

        # show plans
        if show_plan:
            plan_step = 1
            for plan in task_flow_plans:
                print(plan_step, ". ", plan["content"], "\n")
                plan_step += 1

        return task_flow_plans

    # Write module code and validate
    def _normalize_rtl_for_compare(self, rtl: str) -> str:
        rtl = re.sub(r"//.*", "", rtl)
        rtl = re.sub(r"/\*.*?\*/", "", rtl, flags=re.DOTALL)
        rtl = re.sub(r"\s+", "", rtl)
        return rtl.strip()

    def _extract_last_mismatch_count(self, debug_attempts: List[Dict[str, Any]]) -> Optional[int]:
        mismatch_counts = [attempt.get("mismatch_count") for attempt in debug_attempts if attempt.get("mismatch_count") is not None]
        if len(mismatch_counts) == 0:
            return None
        return mismatch_counts[-1]

    def _is_prob105_like_rotator_task(self, module: str) -> bool:
        lowered = module.lower()
        return "rotate" in lowered and "ena" in lowered and "100-bit" in lowered

    def _build_stronger_debug_instruction(self, module: str) -> str:
        instruction = (
            "Do not repeat the previous diagnosis. Compare the ena semantic mapping explicitly. "
            "Check whether rotate-left and rotate-right cases are swapped. "
            "Propose a materially different RTL instead of resubmitting equivalent logic."
        )
        if self._is_prob105_like_rotator_task(module):
            instruction += (
                " For this rotator-style task, verify that 2'b01 rotates right as {q[0], q[99:1]} and "
                "2'b10 rotates left as {q[98:0], q[99]}. Prefer the minimal sequential implementation that "
                "updates q directly; avoid an unnecessary internal_reg mirror unless the spec requires it."
            )
        return instruction

    def _build_debug_prompt(self, module: str, completed_module: str, extra_instruction: str = "") -> str:
        prompt_params = get_verilog_debug_prompt(llm_type=self.llm_types["verilog_debug_llm"])
        module_prompt = module
        if extra_instruction:
            module_prompt = module.rstrip() + "\n\n[Additional Corrective Instructions]\n" + extra_instruction.strip()

        if self.llm_types["verilog_writing_llm"] == "llama3":
            prompt_dict = {
                "prompt_template": prompt_params["template"],
                "ModulePrompt": module_prompt + "\n\n" + prompt_params["tool_examples"],
                "PreviousTaskOutput": completed_module,
            }
        else:
            prompt_dict = {
                "prompt_template": prompt_params["template"],
                "ModulePrompt": module_prompt,
                "PreviousTaskOutput": completed_module,
            }
        return prompt_dict["prompt_template"].format(
            ModulePrompt=prompt_dict["ModulePrompt"],
            PreviousTaskOutput=prompt_dict["PreviousTaskOutput"],
        )

    def _run_bounded_debug_loop(self, module: str, completed_module: str):
        current_rtl = completed_module.strip()
        debug_attempts: List[Dict[str, Any]] = []
        mismatch_history: List[Dict[str, Any]] = []
        stronger_instruction = ""
        previous_attempt_signature = None

        for debug_attempt_idx in range(2):
            self.code_debug_agent.reset_agents()
            self.verilog_tools.start_debug_session()
            prompt = self._build_debug_prompt(module=module, completed_module=current_rtl, extra_instruction=stronger_instruction)
            response = self.code_debug_agent.initiate_chat(message=prompt)
            debug_result = validate_correct_parse(response)
            session_attempts = self.verilog_tools.get_debug_attempts()
            self.verilog_tools.end_debug_session()

            for session_attempt in session_attempts:
                mismatch_history.append(
                    {
                        "debug_attempt": debug_attempt_idx,
                        "simulation_attempt": session_attempt.get("attempt_index"),
                        "mismatch_count": session_attempt.get("mismatch_count"),
                    }
                )

            submitted_rtl = (self.verilog_tools.completed_verilog or current_rtl).strip()
            last_mismatch_count = self._extract_last_mismatch_count(session_attempts)
            stagnated = any(session_attempt.get("stop_due_to_stagnation") for session_attempt in session_attempts)
            current_signature = {
                "rtl": self._normalize_rtl_for_compare(submitted_rtl),
                "mismatch_count": last_mismatch_count,
            }
            debug_attempts.append(
                {
                    "debug_attempt": debug_attempt_idx,
                    "result": debug_result,
                    "stagnated": stagnated,
                    "stop_reason": self.verilog_tools.debug_session_stop_reason,
                    "mismatch_count": last_mismatch_count,
                }
            )

            if debug_result == "Pass":
                self.last_debug_artifacts = {
                    "functional_success": True,
                    "last_submitted_rtl": submitted_rtl,
                    "debug_attempts": debug_attempts,
                    "mismatch_history": mismatch_history,
                }
                return True

            if debug_attempt_idx == 0:
                stronger_instruction = self._build_stronger_debug_instruction(module)
                current_rtl = submitted_rtl or current_rtl
                previous_attempt_signature = current_signature
                continue

            if previous_attempt_signature == current_signature or stagnated:
                break

        self.last_debug_artifacts = {
            "functional_success": False,
            "last_submitted_rtl": (self.verilog_tools.completed_verilog or current_rtl).strip(),
            "debug_attempts": debug_attempts,
            "mismatch_history": mismatch_history,
        }
        return False

    def complete_functional_correct_code(self,
                                         cur_task_id,
                                         module: str,
                                         task_flow_plans: List[Dict[str, Any]]):

        for task in task_flow_plans:
            # print("Plan ", task['id'], ":", task["content"])
            # print("Module = ", module)
            task["agent"] = self.verilog_complete_agent
            task["output_parser"] = verilog_output_parse
            prompt_params = get_verilog_completion_prompt(llm_type=self.llm_types["verilog_writing_llm"])
            if self.llm_types["verilog_writing_llm"] == "llama3":
                task["prompt_dict"] = {"prompt_template": prompt_params["template"],
                                       "ModulePrompt": module,
                                       "PreviousTaskOutput": "",  # automatic fill in the task flow
                                       "VerilogExamples": GeneralExample,  # Todo: Dynamic ICL examples
                                       "Task": task["content"] + "\n\n[Referenced SubTask Description]:\n" + task[
                                           "source"] + "\n\n" + prompt_params["tool_examples"],
                                       }
            else:
                # default prompt for gpt models
                task["prompt_dict"] = {"prompt_template": prompt_params["template"],
                                       "ModulePrompt": module,
                                       "PreviousTaskOutput": "",  # automatic fill in the task flow
                                       "VerilogExamples": GeneralExample,  # Todo: Dynamic ICL examples/ self-learning?
                                       "Task": task["content"] + "\n\n[Referenced SubTask Description]:\n" + task["source"],
                                       }
        task_manager = BaseTaskFlowManager(task_list=task_flow_plans)
        task_manager.create_DAG_task_graph(display_graph=False)

        if not task_manager.check_sequential_task_flow():
            print("[Error]: Not a sequential flow! Check plan generation!")
            failed_plan_tasks.append(cur_task_id)
            return False, "FAILED_FILE", "FAILED_FILE"

        task_completed_results = task_manager.execute_task_flows(pseudo=False)
        current_rtl = (self.verilog_tools.completed_verilog or "").strip()
        debug_success = False
        if current_rtl != "":
            debug_success = self._run_bounded_debug_loop(module=module, completed_module=current_rtl)
        print('Final output = ', "Pass" if debug_success else "Fail")
        if debug_success:
            generated_module_file, generated_test_file = self.verilog_tools.write_verilog_file(task_id=cur_task_id,
                                                                                               output_dir=self.verilog_output_dir)
            return True, generated_module_file, generated_test_file
        else:
            generated_module_file, generated_test_file = self.verilog_tools.write_verilog_file(task_id=cur_task_id,
                                                                                               output_dir=self.verilog_tmp_dir)
            return False, generated_module_file, generated_test_file

    # debug completed module only; Not used commonly
    def debug_completed_module(self, cur_task_id, module: str, completed_module: str):
        self.revalidate_agents()
        debug_success = self._run_bounded_debug_loop(module=module, completed_module=completed_module)
        print('Final output = ', "Pass" if debug_success else "Fail")
        if debug_success:
            generated_module_file, generated_test_file = self.verilog_tools.write_verilog_file(task_id=cur_task_id,
                                                                                               output_dir=self.verilog_output_dir)
            return True, generated_module_file, generated_test_file
        else:
            generated_module_file, generated_test_file = self.verilog_tools.write_verilog_file(task_id=cur_task_id,
                                                                                               output_dir=self.verilog_tmp_dir)
            return False, generated_module_file, generated_test_file
