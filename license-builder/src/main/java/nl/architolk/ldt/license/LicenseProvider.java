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
	public static final String FILE_VERSION = "file.version";

	public LicenseProvider() {
		super();
	}
	
	public Map<String, String> getAdditionalProperties(AbstractLicenseMojo mojo, Properties properties, Document document) {
		try {
			Map<String, String> result = new HashMap<String, String>();
			//Set date to current date of file
			SimpleDateFormat dt = new SimpleDateFormat("yyyy-MM-dd");
			Date timestamp = new Date(document.getFile().lastModified());
			String fileDate = dt.format(timestamp);
			result.put(FILE_TIMESTAMP, fileDate);
			//Set file version to project version OR release version if document date is release date
			String projectVersion = properties.getProperty("project.version");
			String releaseVersion = mojo.properties.get("release.version");
			String releaseDate = properties.getProperty("release.date");
			if (fileDate.equals(releaseDate)) {
				result.put(FILE_VERSION,releaseVersion);
			}
			else {
				result.put(FILE_VERSION,projectVersion);
			}
            return Collections.unmodifiableMap(result);
		} catch (Exception e) {
			throw new RuntimeException("Error excuting LDT license provider", e);
		}
	}

}