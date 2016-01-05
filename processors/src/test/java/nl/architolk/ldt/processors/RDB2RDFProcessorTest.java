package nl.architolk.ldt.processors;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * Unit test for XMLFOProcessor.
 */
public class RDB2RDFProcessorTest 
    extends TestCase
{
    /**
     * Create the test case
     *
     * @param testName name of the test case
     */
    public RDB2RDFProcessorTest( String testName )
    {
        super( testName );
    }

    /**
     * @return the suite of tests being tested
     */
    public static Test suite()
    {
        return new TestSuite( RDB2RDFProcessorTest.class );
    }

    /**
     * Rigourous Test :-)
     */
    public void testRDB2RDFProcessor()
    {
        assertTrue( true );
    }
}
