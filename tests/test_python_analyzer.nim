# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test_python_analyzer.nim - Tests for Python language analyzer

import unittest
import ../src/language_analyzer
import ../src/analyzers/python_analyzer

suite "Python Analyzer":
  test "extracts Python function definitions":
    let code = """
def hello():
    print("Hello")

def greet(name):
    return f"Hi {name}"

async def fetch_data():
    await something()
"""

    let analyzer = createPythonAnalyzer()
    let functions = analyzer.extractFunctions(code, "test.py")

    check functions.len == 3
    check functions[0].name == "hello"
    check functions[0].line == 1
    check functions[1].name == "greet"
    check functions[1].line == 4
    check functions[2].name == "fetch_data"
    check functions[2].line == 7

  test "extracts Python function calls":
    let code = """
def process():
    validate_input()
    transform_data()
    save_to_file()
    save_to_file()
"""

    let analyzer = createPythonAnalyzer()
    let calls = analyzer.extractCalls(code, "process")

    check calls.len == 3

    # Find each call
    var foundValidate = false
    var foundTransform = false
    var foundSave = false
    var saveCount = 0

    for call in calls:
      if call.callee == "validate_input":
        foundValidate = true
        check call.count == 1
      elif call.callee == "transform_data":
        foundTransform = true
        check call.count == 1
      elif call.callee == "save_to_file":
        foundSave = true
        saveCount = call.count

    check foundValidate
    check foundTransform
    check foundSave
    check saveCount == 2

  test "handles Python decorators":
    let code = """
@app.route('/api')
@require_auth
def api_endpoint():
    return data()
"""

    let analyzer = createPythonAnalyzer()
    let functions = analyzer.extractFunctions(code, "test.py")

    check functions.len == 1
    check functions[0].name == "api_endpoint"

  test "handles Python class methods":
    let code = """
class MyClass:
    def method_one(self):
        pass

    def method_two(self):
        self.method_one()
"""

    let analyzer = createPythonAnalyzer()
    let functions = analyzer.extractFunctions(code, "test.py")

    check functions.len == 2
    check functions[0].name == "method_one"
    check functions[1].name == "method_two"

  test "filters Python keywords":
    let code = """
def test():
    if True:
        for i in range(10):
            while i > 0:
                pass
"""

    let analyzer = createPythonAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    # Should only find 'range', not 'if', 'for', 'while'
    check calls.len == 1
    check calls[0].callee == "range"

  test "ignores function calls in comments":
    let code = """
def test():
    # some_function()
    real_function()
"""

    let analyzer = createPythonAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    check calls.len == 1
    check calls[0].callee == "real_function"

  test "ignores function calls in strings":
    let code = """
def test():
    msg = "call this_function()"
    real_function()
"""

    let analyzer = createPythonAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    check calls.len == 1
    check calls[0].callee == "real_function"

  test "handles method calls":
    let code = """
def test():
    obj.method()
    result.transform()
"""

    let analyzer = createPythonAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    check calls.len == 2

    var foundMethod = false
    var foundTransform = false

    for call in calls:
      if call.callee == "method":
        foundMethod = true
      elif call.callee == "transform":
        foundTransform = true

    check foundMethod
    check foundTransform
