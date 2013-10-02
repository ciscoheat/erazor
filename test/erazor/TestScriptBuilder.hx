/**
 * ...
 * @author $(DefaultUser)
 */

package erazor;

import erazor.Parser;
import erazor.ScriptBuilder;

import utest.Assert;

class TestScriptBuilder
{
	var builder : ScriptBuilder;

	public function new()
	{
		
	}
	
	public function setup()
	{
		builder = new ScriptBuilder('__b__');
	}
	
	public function test_If_print_and_literal_TBlocks_are_assembled_correctly()
	{
		var input = [TBlock.literal("Hello "), TBlock.printBlock("name")];
		
		assertScript([
			"__b__.add('Hello ');",
			"__b__.unsafeAdd(name);"
		], builder.build(input));
	}
	
	public function test_If_keyword_TBlocks_are_assembled_correctly()
	{
		var input = [
			TBlock.codeBlock("if(a == 0) {"),
			TBlock.literal('Zero'),
			TBlock.codeBlock("} else if(a == 1 && b == 2) {"),
			TBlock.literal('One'),
			TBlock.codeBlock("} else {"),
			TBlock.literal('Above'),
			TBlock.codeBlock("}")
		];
		
		assertScript([
			"if(a == 0) {",
			"__b__.add('Zero');",
			"} else if(a == 1 && b == 2) {",
			"__b__.add('One');",
			"} else {",
			"__b__.add('Above');",
			"}"
		], builder.build(input));
	}

	public function test_If_for_TBlocks_are_assembled_correctly()
	{
		var input = [
			TBlock.codeBlock("for(u in users) {"),
			TBlock.printBlock('u.name'),
			TBlock.literal('<br>'),
			TBlock.codeBlock('}')
		];
		
		assertScript([
			"for(u in users) {",
			"__b__.unsafeAdd(u.name);",
			"__b__.add('<br>');",
			"}"
		], builder.build(input));
	}

	public function test_If_codeBlocks_are_assembled_correctly()
	{
		var input = [
			TBlock.codeBlock("a = 0; if(b == 2) {"),
			TBlock.literal('TEST'),
			TBlock.codeBlock('}')
		];
		
		assertScript([
			"a = 0; if(b == 2) {",
			"__b__.add('TEST');",
			"}"
		], builder.build(input));
	}
	
	/*
	public function test_If_captures_are_assembled_correctly()
	{
		var input = [
			TBlock.captureBlock('a'),
			TBlock.literal('haxe'),
			TBlock.captureCloseBlock('v'),
			TBlock.literal(' '),
			TBlock.printBlock('uc(v)')
		];
		
		assertScript([
			"__b__ = __string_buf__(__b__);",
			"__b__.add('haxe');",
			"v = __b__.toString();",
			"__b__ = __restore_buf__();",
			"__b__.add(' ');",
			"__b__.add(uc(v));"
			], builder.build(input));
		
		input = [
			TBlock.captureBlock('a'),
			TBlock.literal('ha'),
			TBlock.captureBlock('b'),
			TBlock.literal('x'),
			TBlock.captureCloseBlock('v2'),
			TBlock.literal('e'),
			TBlock.captureCloseBlock('v1')
		];
		
		assertScript([
			// here is the thing ... __b__ is the current output
			// we pass it on the stack to be able to pop it later
			// and replace the current scope with a brand new one
			"__b__ = __string_buf__(__b__);",
			"__b__.add('ha');",
			// a second capture starts here
			// scope will be the brand new and the current is pushed on the stack
			"__b__ = __string_buf__(__b__);",
			"__b__.add('x');",
			// current scope is v2 ... we use it to define the var
			"v2 = __b__.toString();",
			// restore popping the stack
			// we are now in the scope of the first capture
			"__b__ = __restore_buf__();",
			"__b__.add('e');",
			"v1 = __b__.toString();",
			// restore the global scop
			// we don't even need to check if the stack is empty beucase it can't be
			"__b__ = __restore_buf__();",
		], builder.build(input));
	}
	*/

	private function assertScript(lines : Array<String>, expected : String)
	{
		Assert.equals(expected, lines.join("\n") + "\n");
	}
}