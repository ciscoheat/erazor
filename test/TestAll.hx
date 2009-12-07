import htemplate.TestHTemplate;
import htemplate.TestHTemplateParser;
import htemplate.TestScriptBuilder;
import htemplate.TestSyntax;

class TestAll 
{

	static function main() 
	{
		var runner = new utest.Runner();
		runner.addCase(new TestHTemplate());
		runner.addCase(new TestHTemplateParser());
		runner.addCase(new TestScriptBuilder());
		runner.addCase(new TestSyntax());
		
		var report = new utest.ui.text.TraceReport(runner);
		runner.run();
	}	
}