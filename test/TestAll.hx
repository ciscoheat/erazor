import htemplate.TestHTemplate;
import htemplate.TestSyntax;
/**
 * ...
 * @author $(DefaultUser)
 */


class TestAll 
{

	static function main() 
	{
		var runner = new utest.Runner();
		runner.addCase(new TestHTemplate());
		runner.addCase(new TestSyntax());
		var report = new utest.ui.text.TraceReport(runner);
		runner.run();
	}
	
}