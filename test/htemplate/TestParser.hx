/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

import htemplate.Parser;
import utest.Assert;

class TestParser
{
	var parser : Parser;

	public function new();
	
	public function setup()
	{
		parser = new Parser();
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
		var output = parser.parse('Hello {:name}');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock("name")], output);
		
		// String substitution
		output = parser.parse('Hello {:"Boris"}');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock('"Boris"')], output);

		// String substitution with escaped quotation marks
		output = parser.parse('Hello {:a + "A \\" string."}');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock('a + "A \\" string."')], output);

		output = parser.parse("Hello {:a + 'A \\' string.'}");
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock("a + 'A \\' string.'")], output);

		output = parser.parse('{:"\'Mixing\'"}');
		Assert.same([TBlock.printBlock("\"'Mixing'\"")], output);
		
		// Braces around var
		output = parser.parse('Hello {{:name}}');
		Assert.same([TBlock.literal("Hello {"), TBlock.printBlock('name'), TBlock.literal('}')], output);
		
		// Concatenated vars with space between start/end of block
		output = parser.parse('{: user.firstname + " " + user.lastname }');
		Assert.same([TBlock.printBlock('user.firstname + " " + user.lastname')], output);
		
		output = parser.parse('{ : this.isNotGood }');
		Assert.same([TBlock.literal("{ : this.isNotGood }")], output);
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
	
	
	public function test_If_evalblocks_are_parsed_correctly()
	{
		// Single codeblock
		var output = parser.parse('Test: {eval}a = 0; Lib.print("Evil Bracke}");{end}');
		Assert.same([
			TBlock.literal("Test: "),
			TBlock.codeBlock('a = 0; Lib.print("Evil Bracke}");')
		], output);
		
		// Nested codeblock
		var output = parser.parse('{eval} a = 0; if(b == 2) { Lib.print("Ok"); }{end}');
		Assert.same([
			TBlock.codeBlock('a = 0; if(b == 2) { Lib.print("Ok"); }')
		], output);
	}

	public function test_If_captures_are_parsed_correctly()
	{
		var output = parser.parse('{set v}haxe{end} {:uc(v)}');
		Assert.same([
			TBlock.captureBlock('v'),
			TBlock.literal('haxe'),
			TBlock.captureCloseBlock('v'),
			TBlock.literal(' '),
			TBlock.printBlock('uc(v)')
		], output);
		
		output = parser.parse('{set v1}ha{set v2}x{end}e{end}');
		Assert.same([
			TBlock.captureBlock('v1'),
			TBlock.literal('ha'),
			TBlock.captureBlock('v2'),
			TBlock.literal('x'),
			TBlock.captureCloseBlock('v2'),
			TBlock.literal('e'),
			TBlock.captureCloseBlock('v1'),
		], output);
	}

	public function test_If_keyword_blocks_are_parsed_correctly()
	{
		// if
		var output = parser.parse('Test: {if(a == 0)}Zero{end}');
		Assert.same([TBlock.literal("Test: "), TBlock.ifBlock("a == 0"), TBlock.literal('Zero'), TBlock.closeBlock], output);
		
		// no parenthesis
		output = parser.parse('Test: {if a == 0}Zero{end}');
		Assert.same([TBlock.literal("Test: "), TBlock.ifBlock("a == 0"), TBlock.literal('Zero'), TBlock.closeBlock], output);

		// if/else if/else
		output = parser.parse('{if (a == 0)}Zero{else if (a == 1 && b == 2)}One{else}Above{end}');
		Assert.same([
			TBlock.ifBlock("a == 0"),
			TBlock.literal('Zero'),
			TBlock.elseifBlock("a == 1 && b == 2"),
			TBlock.literal('One'),
			TBlock.elseBlock,
			TBlock.literal('Above'),
			TBlock.closeBlock,
		], output);
		
		// for
		output = parser.parse('{for (u in users) }{:u.name}<br>{end}');
		Assert.same([
			TBlock.forBlock("u in users"),
			TBlock.printBlock('u.name'),
			TBlock.literal('<br>'),
			TBlock.closeBlock,
		], output);
		
		// for no parenthesis
		output = parser.parse('{for u in users}{:u.name}<br>{end}');
		Assert.same([
			TBlock.forBlock("u in users"),
			TBlock.printBlock('u.name'),
			TBlock.literal('<br>'),
			TBlock.closeBlock,
		], output);
		
		// while
		output = parser.parse('{while ( a > 0 ) }{? a--; }{end}');
		Assert.same([
			TBlock.whileBlock("a > 0"),
			TBlock.codeBlock('a--;'),
			TBlock.closeBlock,
		], output);
		
		// while no parenthesis
		output = parser.parse('{while a > 0}{? a--; }{end}');
		Assert.same([
			TBlock.whileBlock("a > 0"),
			TBlock.codeBlock('a--;'),
			TBlock.closeBlock,
		], output);
		
		// Invalid open block (case sensitive)
		Assert.same([TBlock.literal('{IF(a == 2)}')], parser.parse('{IF(a == 2)}'));
		
		// Invalid open block (white space)
		Assert.same([TBlock.literal('{ if(a == 2)}')], parser.parse('{ if(a == 2)}'));
	}
	
	public function test_If_parsing_exceptions_are_thrown()
	{
		var self = this;
		
		// Unclosed tags
		Assert.raises(function() {
			self.parser.parse('{if (incompleted == true)');
		});
		
		Assert.raises(function() {
			self.parser.parse('{:echo{{');
		});
		
		// Unclosed strings
		Assert.raises(function() {
			self.parser.parse('{:a + "unclosed string}');
		});
		
		Assert.raises(function() {
			self.parser.parse("{if(a == 'Oops)}");
		});
		
		// Unclosed captures
		Assert.raises(function() {
			self.parser.parse('{set v}');
		});
		
		Assert.raises(function() {
			self.parser.parse('{set v1}{set v2}{end}');
		});
	}
}