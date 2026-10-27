$port = 8080
$path = "c:\kaprao-shop"
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
$listener.Start()
Write-Host "TCP Web Server listening on port $port (Any Host header allowed)..."

while ($true) {
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        
        $requestLine = $reader.ReadLine()
        if ($null -ne $requestLine) {
            # Read all request headers until blank line
            while (($line = $reader.ReadLine()) -ne "") {
                if ($null -eq $line) { break }
            }
            
            $parts = $requestLine.Split(' ')
            $url = if ($parts.Length -gt 1) { $parts[1] } else { "/" }
            if ($url -eq "/" -or $url -eq "") { $url = "/index.html" }
            
            $filePath = Join-Path $path ($url.TrimStart('/').Split('?')[0])
            
            if (Test-Path $filePath -PathType Leaf) {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $mime = "text/html; charset=utf-8"
                if ($filePath.EndsWith(".css")) { $mime = "text/css" }
                elseif ($filePath.EndsWith(".js")) { $mime = "application/javascript" }
                elseif ($filePath.EndsWith(".png")) { $mime = "image/png" }
                elseif ($filePath.EndsWith(".jpg") -or $filePath.EndsWith(".jpeg")) { $mime = "image/jpeg" }
                
                $header = "HTTP/1.1 200 OK`r`nContent-Type: $mime`r`nContent-Length: $($content.Length)`r`nConnection: close`r`n`r`n"
                $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                $stream.Write($headerBytes, 0, $headerBytes.Length)
                $stream.Write($content, 0, $content.Length)
            } else {
                $notFound = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
                $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($notFound.Length)`r`nConnection: close`r`n`r`n"
                $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                $stream.Write($headerBytes, 0, $headerBytes.Length)
                $stream.Write($notFound, 0, $notFound.Length)
            }
        }
        $client.Close()
    } catch {
        # continue
    }
}
