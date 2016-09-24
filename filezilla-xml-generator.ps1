Function Generate-Filezilla-XML([String] $csvfile, [String] $extraxml, [String] $outputxml) {	
    ##### Functions #####
	Function generate-xml([String] $usr, [String] $pwds_sha, [String] $salt) {
        #convert salt to XML syntax
        $saltxml = ConvertTo-Xml $salt -As Stream
        #use Split() to remove XML markers from ConverTo-Xml
        $split_pattern = "<Object Type=`"System.String`">","</Object>"
        $split_option = [System.StringSplitOptions]::RemoveEmptyEntries
		$saltdata = $saltxml[2].Split($split_pattern, $split_option)

        #generate XML using the dumbest but intuitive way
		(
		"<User Name=`"" + $usr + "`">`
		<Option Name=`"Pass`">" + $pwds_sha + "</Option>`
		<Option Name=`"Salt`">" + $saltdata + "</Option>"
		) | Out-File -Append $outputxml
		
        #append extraxml and ending marker
		Get-Content $extraxml  | Out-File -Append $outputxml
		"</User>" | Out-File -Append $outputxml
	}

    #Function get-sha512 originates from Get-StringHash by Jon Gurgul
	#https://gallery.technet.microsoft.com/scriptcenter/Get-StringHash-aa843f71
	#http://jongurgul.com/blog/get-stringhash-get-filehash/
	Function get-sha512([String] $String,$HashName = "SHA512") {
		$StringBuilder = New-Object System.Text.StringBuilder
		[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
			[Void]$StringBuilder.Append($_.ToString("X2")) #edit: upper case needed
		}
		$StringBuilder.ToString()
	}	

    #main goes here
	Add-Type -AssemblyName System.Web #System.Web.Security.Membership.GeneratePassword()
	
	$list = Get-Content $csvfile
	$list = $list | Where-Object{$_} #delete empty lines
	
	foreach ($member in $list) {
		$salt = [System.Web.Security.Membership]::GeneratePassword(64,16)
		$data = $member.Split(",") #data[0] is username, data[1] is plain password
		$pwdsalt = $data[1] + $salt
		generate-xml $data[0] (get-sha512 $pwdsalt) $salt
	}
}