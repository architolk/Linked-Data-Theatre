package nl.architolk.ldt.license;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.api.errors.GitAPIException;

import java.io.File;
import java.io.IOException;

public class GitLookUp {

    private final Repository repository;
	private final GitPathResolver pathResolver;
	
	public GitLookUp(File anyFile) throws IOException {
		super();
        this.repository = new FileRepositoryBuilder().findGitDir(anyFile).build();
        /* A workaround for  https://bugs.eclipse.org/bugs/show_bug.cgi?id=457961 */
        this.repository.getObjectDatabase().newReader().getShallowCommits();
		this.pathResolver = new GitPathResolver(repository.getWorkTree().getAbsolutePath());
	}
	
	public String getCommitMessage(File file) throws GitAPIException {
		String repoRelativePath = pathResolver.relativize(file);
		String commitMessage = "";
		
		Iterable<RevCommit> commits = new Git(repository).log().addPath(repoRelativePath).setMaxCount(1).call();
		for (RevCommit commit : commits) {
			commitMessage = commit.getShortMessage();
		}
		return commitMessage.replaceFirst("^Release ","");
	}
}