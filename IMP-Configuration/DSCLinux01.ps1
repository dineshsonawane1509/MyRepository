Configuration DSCLinux01
{
    Import-DSCResource -Module nx
    
    Node "Linux1"
    {
        nxPackage apache2Install
        {
            Name = "apache2"
            Ensure = "Present"
            PackageManager = "Apt"
        }

        nxService apache2Service
        {
            Name = "apache2"
            Controller = "init"
            Enabled = $true
            State = "Running"
        }    

        nxFile apache2File
        {
            Ensure = "Present"
            Type = "File"
            DestinationPath = "/var/www/index.html"
            Contents = '<!DOCTYPE html>
<html>
<head>
<title>My DSC Linux Apache Test Page</title>
</head>
<body bgcolor="#00c87c">
<h3 style="color:blue">This Apache server and webpage is installed and configured by DSC on Linux</h3>
</body>
</html>'
        }
    }
}