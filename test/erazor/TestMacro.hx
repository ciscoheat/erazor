package erazor;
import utest.Assert;

/**
 * ...
 * @author Waneck
 */

class TestMacro 
{

	public function new() 
	{
		
	}
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		var template = new MacroTest0();
		Assert.equals('Hello Boris', template.execute( { name: 'Boris' } ));
	}
/*
	public function test_If_basic_vars_are_parsed_correctly_with_hash()
	{
		var vars = new Hash<String>();
		vars.set('name', 'Boris');
		
		var template = new MacroTest0();
		Assert.equals('Hello Boris', template.execute(vars));
	}
*/
	public function test_If_basic_vars_are_parsed_correctly_with_whitespace()
	{
		var template = new MacroTest1();
		Assert.equals("  Hello Boris  \n ", template.execute( { name: 'Boris' } ));
	}
	
	public function test_If_keyword_vars_are_parsed_correctly()
	{
		var template = new MacroTest2();
		Assert.equals("1-2-3-4-5-", template.execute( { numbers: [1, 2, 3, 4, 5] } ));

		var template = new MacroTest3();
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", template.execute({
			users: [{name: 'Boris'}, {name: 'Doris'}, {name: 'Someone else'}]
		}));
		
		var template = new MacroTest4();
		Assert.equals("987654321", template.execute({}));
		
		var template = new MacroTest5();
		Assert.equals("987654321", template.execute({}));
		
	}
	
	public function test_Static_method_call():Void
	{
		var template = new MacroTest6();
		Assert.equals("-1", template.execute({x:Math.PI}));
	}
	
	public function test_Block_with_enum_match():Void
	{
		var template = new MacroTest7();
		Assert.equals("object float instance of String ", template.execute({vars:[{}, Math.PI, "hello!"]}));
	}
}

@:template("Hello @name")
class MacroTest0 extends erazor.macro.Template<{name:String}>
{
	
}

@:template("  Hello @name  \n ")
class MacroTest1 extends erazor.macro.Template<{name:String}>
{
	
}

@:template("@for(i in numbers){@(i)-}")
class MacroTest2 extends erazor.macro.Template<{numbers:Array<Int>}>
{
	
}

@:includeTemplate("Test.erazor")
class MacroTest3 extends erazor.macro.Template<{users:Array<{name:String}>}>
{
	
}

@:template("@{ a = 10; }@while(--a > 0){@a}")
class MacroTest4 extends erazor.macro.Template<Dynamic>
{
	
}

@:template("@{var a = 9; var b = '9'; while(--a > 0){b += a;} }@b")
class MacroTest5 extends erazor.macro.Template<Dynamic>
{
	
}

@:template("@Math.cos(x)")
class MacroTest6 extends erazor.macro.Template<{x:Float}>
{
	
}

@:template("@for (_var in vars)
	{@{
			var x = switch(Type.typeof(_var))
			{
				case TObject: \"object \";
				case TFloat: \"float \";
				case TClass(i): \"instance of \" + Type.getClassName(i) + \" \";
				default: \"other \";
			}
		}@x}")
class MacroTest7 extends erazor.macro.Template<{vars:Array<Dynamic>}>
{

}