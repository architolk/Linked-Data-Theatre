package nl.architolk.ldt.processors;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * Unit test for ExcelConverter.
 */
public class HttpClientProcessorTest 
    extends TestCase
{
    /**
     * Create the test case
     *
     * @param testName name of the test case
     */
    public HttpClientProcessorTest( String testName )
    {
        super( testName );
    }

    /**
     * @return the suite of tests being tested
     */
    public static Test suite()
    {
        return new TestSuite( HttpClientProcessorTest.class );
    }

    /**
     * Rigourous Test :-)
     */
    public void testHttpClientProcessor()
    {
        assertTrue( true );
    }
}
