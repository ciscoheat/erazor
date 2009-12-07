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
	
	public function test_If_TBlocks_are_assembled_correctly()
	{
		var input = [TBlock.literal("Hello "), TBlock.printBlock("name")];
		
		Assert.equals("__b__.concat('Hello ');\n__b__.concat(name);\n", builder.build(input));
	}
}