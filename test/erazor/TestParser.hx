/**
 * ...
 * @author $(DefaultUser)
 */

package erazor;

import erazor.Parser;
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

	public function test_If_escaped_blocks_are_parsed_correctly()
	{
		var output = parser.parse('normal@@email.com');
		Assert.same([TBlock.literal("normal@email.com")], output);

		output = parser.parse('AtTheEnd@');
		Assert.same([TBlock.literal('AtTheEnd@')], output);

		output = parser.parse('more@@than@@one');
		Assert.same([TBlock.literal('more@than@one')], output);

		output = parser.parse('@@@@{hello}');
		Assert.same([TBlock.literal('@@{hello}')], output);
	}

	public function test_If_printblocks_are_parsed_correctly()
	{
		var output : Array<TBlock>;
		
		// Simple substitution
		output = parser.parse('Hello @name');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock("name")], output);
		
		// String substitution
		output = parser.parse('Hello@(name)abc');
		Assert.same([TBlock.literal("Hello"), TBlock.printBlock('name'), TBlock.literal("abc")], output);

		output = parser.parse('Hello @("Boris")');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock('"Boris"')], output);

		// String substitution with escaped quotation marks
		output = parser.parse('Hello @(a + "A \\" string.")');
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock('a + "A \\" string."')], output);

		output = parser.parse("Hello @(a + 'A \\' string.')");
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock("a + 'A \\' string.'")], output);

		output = parser.parse('@("\'Mixing\'")');
		Assert.same([TBlock.printBlock("\"'Mixing'\"")], output);
		
		// Braces around var
		output = parser.parse('Hello {@name}');
		Assert.same([TBlock.literal("Hello {"), TBlock.printBlock('name'), TBlock.literal('}')], output);
		
		// Concatenated vars with space between start/end of block
		output = parser.parse('@( user.firstname + " " + user.lastname )');
		Assert.same([TBlock.printBlock('user.firstname + " " + user.lastname')], output);
	}

	public function test_If_codeblocks_are_parsed_correctly()
	{
		// Single codeblock
		var output = parser.parse('Test: @{a = 0; Lib.print("Evil Bracke}"); }');
		Assert.same([
			TBlock.literal("Test: "),
			TBlock.codeBlock('a = 0; Lib.print("Evil Bracke}");')
		], output);

		// Nested codeblock
		var output = parser.parse('@{ a = 0; if(b == 2) { Lib.print("Ok"); }}');
		Assert.same([
			TBlock.codeBlock('a = 0; if(b == 2) { Lib.print("Ok"); }')
		], output);
		
		// @ in codeblock
		var output = parser.parse('@{ a = 0; if(b == 2) { Lib.print("a@b"); }}');
		Assert.same([
			TBlock.codeBlock('a = 0; if(b == 2) { Lib.print("a@b"); }')
		], output);
	}
	
	public function test_More_complicated_variables()
	{
		var output : Array<TBlock>;
		
		output = parser.parse('@custom(0, 10, "test(")');
		Assert.same([TBlock.printBlock('custom(0, 10, "test(")')], output);
		
		output = parser.parse('@test[a+1]');
		Assert.same([TBlock.printBlock("test[a+1]")], output);
		
		output = parser.parse('@test.users[user.id]');
		Assert.same([TBlock.printBlock('test.users[user.id]')], output);
		
		output = parser.parse('@test.user.id');
		Assert.same([TBlock.printBlock('test.user.id')], output);
		
		output = parser.parse('@getFunction()()');
		Assert.same([TBlock.printBlock('getFunction()()')], output);
	}

	public function test_If_keyword_blocks_are_parsed_correctly()
	{
		// if
		var output = parser.parse('Test: @if(a == 0) { Zero }');
		Assert.same([TBlock.literal("Test: "), TBlock.codeBlock("if(a == 0) {"), TBlock.literal(' Zero '), TBlock.codeBlock("}")], output);
		
		// nested if
		var output = parser.parse('@if(a) { @if(b) { Ok }}');
		Assert.same([
			TBlock.codeBlock("if(a) {"),
			TBlock.literal(' '),
			TBlock.codeBlock("if(b) {"),
			TBlock.literal(' Ok '),
			TBlock.codeBlock('}'),
			TBlock.codeBlock('}')
		], output);
		
		// if/else if/else
		var output = parser.parse('@if (a == 0) { Zero } else if (a == 1 && b == 2) { One } else { Above }');
		Assert.same([
			TBlock.codeBlock("if (a == 0) {"),
			TBlock.literal(' Zero '),
			TBlock.codeBlock("} else if (a == 1 && b == 2) {"),
			TBlock.literal(' One '),
			TBlock.codeBlock('} else {'),
			TBlock.literal(' Above '),
			TBlock.codeBlock('}')
		], output);
		
		// for
		output = parser.parse('@for (u in users) { @u.name<br> }');
		Assert.same([
			TBlock.codeBlock("for (u in users) {"),
			TBlock.literal(' '),
			TBlock.printBlock('u.name'),
			TBlock.literal('<br> '),
			TBlock.codeBlock('}')
		], output);
		
		// while
		output = parser.parse('@while( a > 0 ) { @{a--;} }');
		Assert.same([
			TBlock.codeBlock("while( a > 0 ) {"),
			TBlock.literal(' '),
			TBlock.codeBlock('a--;'),
			TBlock.literal(' '),
			TBlock.codeBlock('}')
		], output);		
	}

	public function test_If_parsing_exceptions_are_thrown()
	{
		var self = this;
		
		// Unclosed tags
		Assert.raises(function() {
			self.parser.parse('@if (incompleted == true)');
		});
		
		Assert.raises(function() {
			self.parser.parse('@{unclosed{{');
		});
		
		Assert.raises(function() {
			self.parser.parse("@if(a == 'Oops)}");
		});		
	}
}