using System;
using System.Collections;
using System.Management.Automation;
using LibGit2Sharp;

namespace Victor
{
    [Cmdlet(VerbsCommon.Get, "Repository")]
    [OutputType(typeof(Repository))]
    public class GetRepositoryCommand : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        public string Path { get; set; } = ".";

        private Hashtable? repos;

        protected override void BeginProcessing()
        {
            var myModule = MyInvocation.MyCommand.Module;
            repos = (Hashtable?)myModule.SessionState.PSVariable.GetValue("REPOSITORIES", null);
            if (repos == null)
            {
                repos = new Hashtable();
                myModule.SessionState.PSVariable.Set("REPOSITORIES", repos);
            }
        }

        protected override void ProcessRecord()
        {
            if (repos == null)
            {
                throw new NullReferenceException(nameof(repos));
            }

            if (!System.IO.Path.IsPathRooted(Path))
            {
                Path = System.IO.Path.Combine(SessionState.Path.CurrentFileSystemLocation.Path, Path);
            }

            var repo = repos[Path];
            if (repo == null)
            {
                repo = new Repository(Path);
                repos[Path] = repo;
            }

            WriteObject(repo);
        }
    }
}
