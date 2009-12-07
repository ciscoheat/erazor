/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

import htemplate.HTemplateParser;
import htemplate.ScriptBuilder;

import utest.Assert;

class TestScriptBuilder
{
	var builder : ScriptBuilder;

	public function new() 
	{
		
	}
	
	public function setup()
	{
		builder = new ScriptBuilder('__b__', 'concat');
	}
	
	public function test_If_print_and_literal_TBlocks_are_assembled_correctly()
	{
		var input = [TBlock.literal("Hello "), TBlock.printBlock("name")];
		
		assertScript([
			"__b__.concat('Hello ');",
			"__b__.concat(name);"
		], builder.build(input));
	}
	
	public function test_If_keyword_TBlocks_are_assembled_correctly()
	{
		var input = [
			TBlock.ifBlock("a == 0"), 
			TBlock.literal('Zero'), 
			TBlock.elseifBlock("a == 1 && b == 2"), 
			TBlock.literal('One'), 
			TBlock.elseBlock,
			TBlock.literal('Above'), 
			TBlock.closeBlock,
		];
		
		assertScript([
			"if(a == 0) {",
			"__b__.concat('Zero');",
			"} else if(a == 1 && b == 2) {",
			"__b__.concat('One');",
			"} else {",
			"__b__.concat('Above');",
			"}"
		], builder.build(input));
	}

	public function test_If_for_TBlocks_are_assembled_correctly()
	{
		var input = [
			TBlock.forBlock("u in users"), 
			TBlock.printBlock('u.name'),
			TBlock.literal('<br>'), 
			TBlock.closeBlock
		];
		
		assertScript([
			"for(u in users) {",
			"__b__.concat(u.name);",
			"__b__.concat('<br>');",
			"}"
		], builder.build(input));
	}

	public function test_If_codeBlocks_are_assembled_correctly()
	{
		var input = [
			TBlock.codeBlock("a = 0; if(b == 2) {"), 
			TBlock.literal('TEST'),
			TBlock.closeBlock
		];
		
		assertScript([
			"a = 0; if(b == 2) {",
			"__b__.concat('TEST');",
			"}"
		], builder.build(input));
	}

	private function assertScript(lines : Array<String>, expected : String)
	{
		Assert.equals(expected, lines.join("\n") + "\n");
	}
}