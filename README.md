# CMPilotCollection
SCCM Console Extension to create "Pilot" collections and sub-collections.

The purpose behind this tool is to support some internal business processes wherein we as packagers are required to deploy larger scale deployments to a smaller “pilot” collection first.  I would imagine that your company has similar requirements as well.

This tool was built using Sapien PowerShell Studio 2015 and was designed to provide a quick and easy way of generating a random sampling of “Pilot Members” for your pilot deployments.

Create Pilot Collection - Main Screen

CREDIT
I’d like to thank Nickolaj Andersen (http://www.scconfigmgr.com) for writing and providing me with the Invoke-ToolInstallation.ps1 script to handle the installation of the Console Extension.  It’s been modified from his original version so I’ll provide a write-up on leveraging this script in a follow-up blog post.

Download
You can download the Console Extension from the TechNet Gallery.

I’ve included the PowerShell Studio Project Files if you would like to tinker and modify for your own use.

Install
To install the Console Extension, extract the .zip file you downloaded to a directory of your choice.  From an Administrative PowerShell Console, run the Invoke-ToolInstallation.PS1 script from the extracted directory.

NOTE: If you currently have the ConfigMgr Console open, you’ll need to close and re-open it.

Usage
To launch the tool, open your ConfigMgr console, and find a collection you wish to use as your “Base” collection.  This would typically be the collection you use for your final (Production) deployment.

The tool can be accessed from the Ribbon or the Right-Click Context Menu as shown below.

Right-Click MenuRibbon Icon

There are only two items you need to fill in.  The Pilot Collection Name and the Percentage of the original (base) collection to use as your pilot members.  The User Interface will update as you type to tell you how many members will be added to your new collection.

Create Pilot Collection - Main Screen

When you are finished, click the button, sit back and relax.  Once your collection is created you can deploy whatever you want to it.

NOTE: Large collections may take several minutes to process and add members.
