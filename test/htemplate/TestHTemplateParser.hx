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
		
	}
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		parser = new HTemplateParser();		
		var output = parser.parse('Hello {$name}');
		
		Assert.same([TBlock.literal("Hello "), TBlock.printBlock("name")], output);
	}
}