package nl.architolk.ldt.license;

import com.mycila.maven.plugin.license.PropertiesProvider;
import com.mycila.maven.plugin.license.document.Document;
import com.mycila.maven.plugin.license.AbstractLicenseMojo;
import java.io.File;
import java.io.IOException;
import java.util.Map;
import java.util.Properties;
import java.util.HashMap;
import java.util.Collections;
import java.util.Date;
import java.text.SimpleDateFormat;

public class LicenseProvider implements PropertiesProvider {

	public static final String FILE_TIMESTAMP = "file.date";
	public static final String FILE_VERSION = "file.version";

	private volatile GitLookUp gitLookUp;
	
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
			//Get git information
			String commitVersion = getGitLookUp(document.getFile()).getCommitMessage(document.getFile());
			//mojo.warn("COMMIT: %s",commitVersion);
			//Set file version to project version OR release version if document date is release date OR commit version if document date is not after patch date
			String projectVersion = properties.getProperty("project.version");
			String releaseVersion = mojo.properties.get("release.version");
			String releaseDate = properties.getProperty("release.date");
			String patchDate = properties.getProperty("patch.date");
			if (fileDate.equals(releaseDate)) {
				//Filedate = releasedate, so the version should be the release version
				result.put(FILE_VERSION,releaseVersion);
			}
			else {
				if ((fileDate.compareTo(patchDate)<=0) && (releaseDate.compareTo(patchDate)<0)) {
					//File is older (or the same) as the patch date, so it's version should be the commit version of the file
					//Except: when the patchdate is older than the release date, the patchdate should be ignored
					result.put(FILE_VERSION,commitVersion);
				} else {
					//File has changed after patch, so version should be current project version
					result.put(FILE_VERSION,projectVersion);
				}
			}
            return Collections.unmodifiableMap(result);
		} catch (Exception e) {
			throw new RuntimeException("Error excuting LDT license provider", e);
		}
	}

	private GitLookUp getGitLookUp(File file) throws IOException {
		if (gitLookUp == null) {
			synchronized (this) {
				if (gitLookUp == null) {
					gitLookUp = new GitLookUp(file);
				}
			}
		}
		return gitLookUp;
	}
	
}