package nl.architolk.ldt.processors;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * Unit test for ExcelConverter.
 */
public class ExcelConverterTest 
    extends TestCase
{
    /**
     * Create the test case
     *
     * @param testName name of the test case
     */
    public ExcelConverterTest( String testName )
    {
        super( testName );
    }

    /**
     * @return the suite of tests being tested
     */
    public static Test suite()
    {
        return new TestSuite( ExcelConverterTest.class );
    }

    /**
     * Rigourous Test :-)
     */
    public void testExcelConverter()
    {
        assertTrue( true );
    }
}
