package nl.architolk.ldt.license;

import com.mycila.maven.plugin.license.PropertiesProvider;
import com.mycila.maven.plugin.license.document.Document;
import com.mycila.maven.plugin.license.AbstractLicenseMojo;
import java.util.Map;
import java.util.Properties;
import java.util.HashMap;
import java.util.Collections;
import java.util.Date;
import java.text.SimpleDateFormat;

public class LicenseProvider implements PropertiesProvider {

	public static final String FILE_TIMESTAMP = "file.date";

	public LicenseProvider() {
		super();
	}
	
	public Map<String, String> getAdditionalProperties(AbstractLicenseMojo mojo, Properties properties, Document document) {
		try {
			Map<String, String> result = new HashMap<String, String>();
			SimpleDateFormat dt = new SimpleDateFormat("yyyy-MM-dd");
			Date timestamp = new Date(document.getFile().lastModified());
			result.put(FILE_TIMESTAMP, dt.format(timestamp));
            return Collections.unmodifiableMap(result);
		} catch (Exception e) {
			throw new RuntimeException("Error excuting LDT license provider", e);
		}
	}

}