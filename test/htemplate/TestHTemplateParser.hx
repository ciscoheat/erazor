/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

import htemplate.HTemplateParser;
import utest.Assert;

class TestHTemplateParser
{
	var parser : HTemplateParser;

	public function new() 
	{
		
	}
	
	public function setup()
	{
		parser = new HTemplateParser();
	}

	public function test_If_literals_are_parsed_correctly()
	{
		// Plain text
		var output = parser.parse('Hello there\nHow are you?');		
		Assert.same([TBlock.literal("Hello there\nHow are you?")], output);
	}

	public function test_If_literals_with_braces_are_parsed_correctly()
	{
		// Braces but no block
		var output = parser.parse('{Start and end}');
		Assert.same([TBlock.literal("{Start and end}")], output);
		
		// Braces but no block inside quotes
		output = parser.parse('"This" is a "{string}"');
		Assert.same([TBlock.literal('"This" is a "{string}"')], output);
	}

	public function test_If_printblocks_are_parsed_correctly()
	{
		// Simple substitution
		var output = parser.parse('Hello {$name}');		
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock("name")], output);
		
		// String substitution
		output = parser.parse('Hello {$"Boris"}');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock('"Boris"')], output);
		
		// Braces around var
		output = parser.parse('Hello {{$name}}');		
		Assert.same([TBlock.literal("Hello {"), TBlock.printBlock('name'), TBlock.literal('}')], output);
		
		// Concatenated vars with space between start/end of block
		output = parser.parse('{$ user.firstname + " " + user.lastname }');
		Assert.same([TBlock.printBlock('user.firstname + " " + user.lastname')], output);
	}
	
	/*
	public function test_If_openBlocks_are_parsed_correctly()
	{
		var output = parser.parse('Test: {# a = 0; while(a < 10) { a++; } }');
		Assert.same([TBlock.literal("Test:"), TBlock.codeBlock("name")], output);		
	}
	*/
}