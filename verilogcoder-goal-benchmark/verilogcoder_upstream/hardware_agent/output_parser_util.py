#
# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# Author : Chia-Tung (Mark) Ho, NVIDIA
#

import re
from autogen.agentchat.chat import ChatResult

def extract_verilog_code_blocks(text):
    """
    Extracts code blocks enclosed between triple backticks (```) from the given text.

    Args:
        text (str): The input text containing code blocks.

    Returns:
        list: A list of code blocks found in the text.
    """
    # Regular expression to match code blocks enclosed in triple backticks
    pattern = re.compile(r'```verilog(.*?)```', re.DOTALL)

    # Find all matches of the pattern in the text
    code_blocks = pattern.findall(text)

    return code_blocks


def verilog_output_parse(response: ChatResult) -> str:

    result = None
    chat_history = getattr(response, "chat_history", None)
    if not chat_history:
        return getattr(response, "summary", "")

    for k in reversed(range(len(chat_history))):
        chat = chat_history[k]
        if not isinstance(chat, dict):
            continue
        chat_content = chat.get("content")
        if not isinstance(chat_content, str) or not chat_content:
            continue
        content = extract_verilog_code_blocks(chat_content)
        if len(content) > 0:
            result = content[-1]
            return result
    return getattr(response, "summary", "")

def validate_correct_parse(response: ChatResult) -> str:

    print("Validating correct parse")
    try:
        chat_history = getattr(response, "chat_history", None)
        if not chat_history:
            return "Fail"

        for k in reversed(range(len(chat_history))):
            chat = chat_history[k]
            if not isinstance(chat, dict):
                continue
            content = chat.get("content")
            if not isinstance(content, str):
                continue
            if "[Compiled Success]" in content and "[Function Check Success]" in content:
                return "Pass"
    except Exception as exc:
        print(f"validate_correct_parse fallback due to parse error: {exc}")
        return "Fail"

    return "Fail"
