package nl.architolk.ldt.processors;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * Unit test for ExcelSerializer.
 */
public class ExcelSerializerTest 
    extends TestCase
{
    /**
     * Create the test case
     *
     * @param testName name of the test case
     */
    public ExcelSerializerTest( String testName )
    {
        super( testName );
    }

    /**
     * @return the suite of tests being tested
     */
    public static Test suite()
    {
        return new TestSuite( ExcelSerializerTest.class );
    }

    /**
     * Rigourous Test :-)
     */
    public void testExcelSerializer()
    {
        assertTrue( true );
    }
}
