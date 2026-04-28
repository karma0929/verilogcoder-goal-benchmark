#
# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# Author : Chia-Tung (Mark) Ho, NVIDIA
#

# Example of User write this file use hardware agent
import os
import json
import re
import copy
from hardware_agent.hardware_general_agent import HardwareAgent
from hardware_agent.tools_utility import get_tools_descriptions, create_tool_tbl
# import tool function from timing summary tools
from autogen.coding import DockerCommandLineCodeExecutor, LocalCommandLineCodeExecutor
from autogen import config_list_from_json
# using the react prompt
from hardware_agent.examples.VerilogCoder.prompt_templates import Verilog_Plan_Template_Prompt, \
    SUBTASK_FORMAT_EXAMPLE, Verilog_Signal_Extract_Template_Prompt, Verilog_signal_extraction_hint
from hardware_agent.examples.VerilogCoder.ICL_examples import GeneralExample, SequentialCircuitExample, \
    BCDCounterExample, LemmingsExample, SumOfProductToProductOfSumExample
from hardware_agent.examples.VerilogCoder.verilog_tools_class import VerilogToolKits
from hardware_agent.examples.VerilogCoder.verilog_examples_manager import VerilogCaseManager
from typing import Any, Callable, Dict, List, Literal, Optional, Tuple, Type, TypeVar, Union, Annotated
from hardware_agent.examples.VerilogCoder.verilog_tools_class import sequential_flipflop_latch_identify_tool
from hardware_agent.examples.VerilogCoder.verilog_agent_configs import make_llm_config
from autogen.agentchat.chat import ChatResult


def _is_termination_msg(msg: Dict[str, Any]) -> bool:
    content = msg.get("content", "")
    if not isinstance(content, str):
        return False
    stripped = content.strip()
    return stripped.startswith("TERMINATE") or stripped.endswith("TERMINATE")

# Mark: Task planner agent and the knowledge graph entity extraction
"""
Agent for making a backbone plans and graph retrieval corpus
"""
class TaskPlanAgent:

    def __init__(self,
                 config_list: Dict[str, Any],
                 work_dir: str="coding"):

        """
        Fix the llm configuration for reproducible result. source: verilog_task_flow_planner.py
        """
        os.makedirs("coding", exist_ok=True)
        # Use docker executor for running code in a container if you have docker installed.
        # code_executor = DockerCommandLineCodeExecutor(work_dir="coding")
        code_executor = LocalCommandLineCodeExecutor(work_dir="coding")
        plan_tool_config = [
            {'function_call': sequential_flipflop_latch_identify_tool,
             'executor': "user",
             'caller': "planner",
             'name': "sequential_flipflop_latch_identify_tool",
             'description': '\tUse this tool to identify sequential element with the clock and the signal waveforms.'
                            '\n\tInput the sequential_signal_name in string format, '
                            'time_sequence as a sequence of time points in string format. '
                            'clock_waveform as a sequence of numbers in string format, '
                            'and sequential_signal_waveform as a sequence of numbers corresponding to the clock_waveform in string format. '
                            'Make sure the sequence length is smaller than 20. '
                            'Output is the string of identified flip-flop, latch, or combinational logic information.',
             'tool_examples': ''}
        ]
        self.plan_resource_manage_group_chat_configs = {'group_chat': {'speaker_selection_method': "round_robin",
                                                                  'messages': [],
                                                                  'max_round': 100},
                                                   'chat_manager': {
                                                       'is_termination_msg': _is_termination_msg,
                                                       'llm_config': {"config_list": config_list, "cache_seed": None}},
                                                   }

        self.plan_resource_manage_agent_configs = [
            {'type': 'UserProxyAgent',
             'tools': ['sequential_flipflop_latch_identify_tool'],
             'base_agent_config': {'name': 'user',
                                   'description': 'User proxy who ask questions.',
                                   'human_input_mode': "NEVER",
                                   'is_termination_msg': _is_termination_msg,
                                   'max_consecutive_auto_reply': 20,
                                   'code_execution_config': False,
                                   }
             },
            {'type': 'AssistantAgent',
             'tools': ['sequential_flipflop_latch_identify_tool'],
             'base_agent_config': {'name': 'planner',
                                   'llm_config': make_llm_config(config_list=config_list, cache_seed=None, temperature=0.1, top_p=1),
                                   'description': "Planner assistant to break down the task into subtasks for completing the verilog code.",
                                   'is_termination_msg': _is_termination_msg,
                                   'max_consecutive_auto_reply': 20,
                                   # the default system message of the AssistantAgent is overwritten here
                                   'system_message': "You are a verilog RTL designer. You suggest the verilog block implementation"
                                                     " plan for verilog engineer to generate the verilog code. Do not suggest concrete "
                                                     "code. For any action beyond writing code or reasoning, convert it to a step that "
                                                     "can be implemented by writing code. For example, browsing the web can be implemented "
                                                     "by writing code that reads and prints the content of a web page."
                                                     " You need to make the plan that following the [Rules]!"
                                                     " You need to follow the modified plans from the plan_verify_assistant! "
                                                     "You can use the provided sequential_flipflop_latch_identify_tool to identify the signal element with the provided waveform for making plans. "
                                                     "Return the subtasks of the created plan in json format!",
                                   }
             },
            {'type': 'AssistantAgent',
             'base_agent_config': {'name': 'plan_verify_assistant',
                                   'llm_config': make_llm_config(config_list=config_list, cache_seed=None, temperature=0.1, top_p=1),
                                   'description': "Assistant who verify the subtasks and plan from planner match the user instruction.",
                                   'is_termination_msg': _is_termination_msg,
                                   'max_consecutive_auto_reply': 20,
                                   # the default system message of the AssistantAgent is overwritten here
                                   'system_message': "You are a verilog RTL designer. You verify the subtasks and plan from planner.\nLet's think step by step."
                                                     " You need to identify the mismatches of the plan and user instruction, and any rule violations in [Rules] of the plan. Suggest "
                                                     "planner modify the plan if needed. Always return the plan in json format. If the plan is good enough, Reply TERMINATE outside of ```json and ``` bracket in the response.",
                                   }
             }
        ]

        self.plan_agent = HardwareAgent(agent_configs=self.plan_resource_manage_agent_configs, tool_configs=plan_tool_config,
                                        group_chat_kwargs=self.plan_resource_manage_group_chat_configs)

        """
        Verilog Entity Extraction Agent. source: verilog_circuit_node_extraction.py
        """

        self.entity_extraction_manage_group_chat_configs = {'group_chat': {'speaker_selection_method': "round_robin",
                                                                  'messages': [],
                                                                  'max_round': 100},
                                                   'chat_manager': {
                                                       'is_termination_msg': _is_termination_msg,
                                                       'llm_config': {"config_list": config_list, "cache_seed": None}},
                                                   }

        self.entity_extraction_agent_configs = [
            {'type': 'UserProxyAgent',
             'base_agent_config': {'name': 'user',
                                   'description': 'User proxy who ask questions.',
                                   'human_input_mode': "NEVER",
                                   'is_termination_msg': _is_termination_msg,
                                   'max_consecutive_auto_reply': 20,
                                   'code_execution_config': False,
                                   }
             },
            {'type': 'AssistantAgent',
             'base_agent_config': {'name': 'verilog_engineer',
                                   'llm_config': make_llm_config(config_list=config_list, cache_seed=None, temperature=0, top_p=1),
                                   'description': "verilog engineer extract the signal and signal transition into the json format.",
                                   'is_termination_msg': _is_termination_msg,
                                   'max_consecutive_auto_reply': 20,
                                   # the default system message of the AssistantAgent is overwritten here
                                   'system_message': "You are a verilog RTL designer. You identify the signal and original signal transition description from "
                                                     " the module description. Don't implement the verilog code! Then return the extracted signals and signal transitions in "
                                                     "json format. When you finished, Reply TERMINATE in the response.",
                                   }
             }
        ]

        self.entity_extraction_agent = HardwareAgent(agent_configs=self.entity_extraction_agent_configs, tool_configs=[],
                                                     group_chat_kwargs=self.entity_extraction_manage_group_chat_configs)

        # build KG graph
        os.makedirs(work_dir, exist_ok=True)
        # Use docker executor for running code in a container if you have docker installed.
        self.code_executor = LocalCommandLineCodeExecutor(work_dir=work_dir)

    def revalidate_llm_config(self):
        self.plan_agent.revalidate_llm_config()
        self.entity_extraction_agent.revalidate_llm_config()

    def extract_json(self, text):
        """
           Extracts json enclosed between triple backticks (```) from the given text.

           Args:
               text (str): The input text containing json blocks.

           Returns:
               list: A list of code blocks found in the text.
           """
        if not isinstance(text, str):
            return []
        # Prefer explicitly typed json fences first.
        pattern = re.compile(r"```(?:json)\s*(.*?)```", re.DOTALL | re.IGNORECASE)
        json_blocks = pattern.findall(text)
        if len(json_blocks) == 0:
            # Fallback for generic code fences.
            pattern = re.compile(r"```(?:\w+)?\s*(.*?)```", re.DOTALL)
            json_blocks = pattern.findall(text)
        return [block.strip() for block in json_blocks if isinstance(block, str) and block.strip() != ""]

    def extract_json_objects(self, text: str):
        """
        Extract top-level JSON object substrings from free-form text.
        This handles planner replies that return raw JSON without fences.
        """
        if not isinstance(text, str):
            return []

        objs = []
        start = -1
        depth = 0
        in_string = False
        escape = False

        for i, ch in enumerate(text):
            if escape:
                escape = False
                continue
            if ch == "\\":
                escape = True
                continue
            if ch == "\"":
                in_string = not in_string
                continue
            if in_string:
                continue
            if ch == "{":
                if depth == 0:
                    start = i
                depth += 1
            elif ch == "}":
                if depth > 0:
                    depth -= 1
                    if depth == 0 and start >= 0:
                        candidate = text[start:i + 1].strip()
                        if candidate:
                            objs.append(candidate)
                        start = -1
        return objs

    def _try_parse_candidate(self, candidate: str, required_keys: Optional[List[str]] = None):
        if not isinstance(candidate, str):
            return None
        candidate = candidate.strip()
        if candidate == "":
            return None
        try:
            parsed = json.loads(candidate)
        except Exception:
            return None
        if required_keys:
            if not isinstance(parsed, dict):
                return None
            for key in required_keys:
                if key not in parsed:
                    return None
        return parsed

    def json_parser(self, response: ChatResult, required_keys: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Robustly parse JSON from chat history.
        Priority:
        1) Non-user agent messages (planner/verification assistant)
        2) User messages as last resort
        """
        prioritized = []
        fallback = []
        for chat in reversed(response.chat_history):
            name = str(chat.get("name", "")).lower()
            content = chat.get("content", "")
            if not isinstance(content, str) or content.strip() == "":
                continue
            if name in {"user", "chat_manager"}:
                fallback.append(content)
            else:
                prioritized.append(content)

        for content in prioritized + fallback:
            candidates = []
            candidates.extend(self.extract_json(content))
            candidates.extend(self.extract_json_objects(content))
            for candidate in candidates:
                parsed = self._try_parse_candidate(candidate, required_keys=required_keys)
                if parsed is not None:
                    return parsed

        raise ValueError(f"Failed to parse valid JSON from chat history. required_keys={required_keys}")


    def _create_rough_plans(self, module: str):

        module_plan_prompt = Verilog_Plan_Template_Prompt.format(ModulePrompt=module,
                                                                 # VerilogExamples=SequentialCircuitExample, # Todo: Dynamic ICL examples
                                                                 # VerilogExamples=BCDCounterExample, # BCD examples
                                                                 # VerilogExamples=LemmingsExample,
                                                                 # VerilogExamples=SumOfProductToProductOfSumExample,
                                                                 VerilogExamples=GeneralExample,
                                                                 SubtaskExample=SUBTASK_FORMAT_EXAMPLE)
        # print("rough plan prompt: ", module_plan_prompt)
        rough_plan = self.plan_agent.initiate_chat(message=module_plan_prompt)
        return self.json_parser(rough_plan, required_keys=["subtasks"])

    def _extract_entity(self, module: str):
        entity_extract_prompt = Verilog_Signal_Extract_Template_Prompt.format(ModulePrompt=module,
                                                                              SignalExtractRule=Verilog_signal_extraction_hint)
        # print("entity extraction prompt: ", entity_extract_prompt)
        entities = self.entity_extraction_agent.initiate_chat(message=entity_extract_prompt)
        return self.json_parser(entities, required_keys=["signal", "state_transitions_description", "signal_examples"])

    def make_plans(self, module: str):

        # make the rough plan
        rough_plan = self._create_rough_plans(module=module)
        if 'subtasks' not in rough_plan.keys():
            print("[Error] Plan format error!\n", rough_plan)
            return
        # print('rough plan = ', rough_plan)
        # Mark: Assign the task plan manually to follow the sequential for writing the same file
        for i in range (len(rough_plan['subtasks'])):
            if i < 1:
                rough_plan["subtasks"][i]["parent_tasks"] = []
                continue
            rough_plan["subtasks"][i]["parent_tasks"] = [rough_plan["subtasks"][i-1]["id"]]

        signal_nodes_extract = self._extract_entity(module=module)
        if 'signal' not in signal_nodes_extract.keys() or \
            'state_transitions_description' not in signal_nodes_extract.keys() or \
            'signal_examples' not in signal_nodes_extract.keys():
            print("[Error] Entity extraction format error!\n", signal_nodes_extract)
            return
        # print('entity extraction = ', signal_nodes_extract)
        return copy.deepcopy(rough_plan['subtasks']), signal_nodes_extract

def test_task_planner():
    # LLM config list
    adlr_config_list = config_list_from_json(env_or_file="OAI_CONFIG_LIST")
    dar_config_list = config_list_from_json(env_or_file="OAI_CONFIG_LIST_DAR")
    # define the tools
    example_json = os.getcwd() + "/hardware_agent/examples/verilog_testcases/VerilogEval_Human.jsonl"
    # verilog eval 2 dir
    example_dir = os.getcwd() + "/hardware_agent/examples/verilog_testcases/verilog-eval-v2/dataset_dumpall/"
    user_task_ids = {"review2015_fsmonehot"}
    case_manager = VerilogCaseManager(file_path=example_dir, task_ids=user_task_ids)
    task_planner_agent = TaskPlanAgent(dar_config_list)
    for i in range(case_manager.total_tasks()):
        cur_task_id = case_manager.get_cur_task_id()
        print("current task id is ", cur_task_id)
        # get the corresponding prompt from verilog eval v2
        # Need to have a function to fetch more than one prompt
        module = case_manager.get_cur_prompt()
        print(task_planner_agent.make_plans(module=module))

if __name__ == '__main__':
    test_task_planner()
