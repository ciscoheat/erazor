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
		
		// Javascript in the template
		output = parser.parse('<script>if(document.getElementById("test")) { alert("ok"); }</script>');
		Assert.same([TBlock.literal('<script>if(document.getElementById("test")) { alert("ok"); }</script>')], output);
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

		// String substitution with escaped quotation marks
		output = parser.parse('Hello {$a + "A \\" string."}');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock('a + "A \\" string."')], output);

		output = parser.parse("Hello {$a + 'A \\' string.'}");
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock("a + 'A \\' string.'")], output);

		output = parser.parse('{$"\'Mixing\'"}');
		Assert.same([TBlock.printBlock("\"'Mixing'\"")], output);
		
		// Braces around var
		output = parser.parse('Hello {{$name}}');		
		Assert.same([TBlock.literal("Hello {"), TBlock.printBlock('name'), TBlock.literal('}')], output);
		
		// Concatenated vars with space between start/end of block
		output = parser.parse('{$ user.firstname + " " + user.lastname }');
		Assert.same([TBlock.printBlock('user.firstname + " " + user.lastname')], output);
	}

	public function test_If_codeblocks_are_parsed_correctly()
	{
		// Single codeblock
		var output = parser.parse('Test: {?a = 0; Lib.print("Evil Bracke}"); }');
		Assert.same([
			TBlock.literal("Test: "),
			TBlock.codeBlock('a = 0; Lib.print("Evil Bracke}");')
		], output);
		
		// Nested codeblock
		var output = parser.parse('{? a = 0; if(b == 2) { Lib.print("Ok"); }}');
		Assert.same([
			TBlock.codeBlock('a = 0; if(b == 2) { Lib.print("Ok"); }')
		], output);		
	}

	public function test_If_keyword_blocks_are_parsed_correctly()
	{
		// if
		var output = parser.parse('Test: {#if(a == 0)}Zero{#}');
		Assert.same([TBlock.literal("Test: "), TBlock.ifBlock("(a == 0)"), TBlock.literal('Zero'), TBlock.closeBlock], output);

		// if/else if/else
		output = parser.parse('{# if (a == 0)}Zero{#else if (a == 1 && b == 2)}One{#else}Above{#}');
		Assert.same([
			TBlock.ifBlock("(a == 0)"),
			TBlock.literal('Zero'),
			TBlock.elseifBlock("(a == 1 && b == 2)"),
			TBlock.literal('One'),
			TBlock.elseBlock,
			TBlock.literal('Above'), 
			TBlock.closeBlock,
		], output);
		
		// for
		output = parser.parse('{#for (u in users) }{$u.name}<br>{#}');
		Assert.same([
			TBlock.forBlock("(u in users)"),
			TBlock.printBlock('u.name'),
			TBlock.literal('<br>'),
			TBlock.closeBlock,
		], output);
		
		// while
		output = parser.parse('{#while ( a > 0 ) }{? a--; }{#}');
		Assert.same([
			TBlock.whileBlock("( a > 0 )"),
			TBlock.codeBlock('a--;'),
			TBlock.closeBlock,
		], output);
	}
	
	public function test_If_parsing_exceptions_are_thrown()
	{
		var self = this;
		
		// Unclosed tags
		Assert.raises(function() {
			self.parser.parse('{#if (incompleted == true)');
		});
		
		Assert.raises(function() {
			self.parser.parse('{$echo{{');
		});
		
		// Unclosed strings
		Assert.raises(function() {
			self.parser.parse('{$a + "unclosed string}');
		});
		
		Assert.raises(function() {
			self.parser.parse("{#if(a == 'Oops)}");
		});
		
		// Invalid open block (case sensitive)
		Assert.raises(function() {
			self.parser.parse('{# IF(a == 2)}');
		});
	}
}