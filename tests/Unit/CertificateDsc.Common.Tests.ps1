#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)/$($script:subModuleName).psm1"

Import-Module $script:subModuleFile -Force -ErrorAction Stop
#endregion HEADER

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

InModuleScope $script:subModuleName {
    $invalidThumbprint = 'Zebra'
    # This is valid thumbprint, but not valid for FIPS
    $invalidFipsThumbprint = '93b885adfe0da089cdf634904fd59f71'

    # This thumbprint is valid (but not FIPS valid)
    $validThumbprint = New-CertificateThumbprint

    # This thumbprint is valid for FIPS
    $validFipsThumbprint = New-CertificateThumbprint -Fips

    $testFile = 'test.pfx'

    $invalidPath = 'TestDrive:'
    $validPath = "TestDrive:\$testFile"

    $cerFileWithSan = "
            -----BEGIN CERTIFICATE-----
            MIIGJDCCBAygAwIBAgITewAAAAqQ+bxgiZZPtgAAAAAACjANBgkqhkiG9w0BAQsF
            ADBDMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHY29udG9z
            bzETMBEGA1UEAwwKTGFiUm9vdENBMTAeFw0xNzA1MDkxNTM5NTJaFw0xOTA1MDkx
            NTM5NTJaMBYxFDASBgNVBAMMC3NvbWVtYWNoaW5lMIIBIjANBgkqhkiG9w0BAQEF
            AAOCAQ8AMIIBCgKCAQEA0Id9FC2vq90HPWraZnAouit8MZI/p/DeucFiCb6mieuP
            017DPCiQKuMQFQmx5VWvv82mpddxmTPtV6zfda0E5R12a11KHJ2mJrK5oR2iuI/I
            P2SJBlNAkLTsvd96zUqQcWCCE/Q2nSrK7nx3oBq4Dd5+wLfUvAMKR45RXK58J4z5
            h3mLxF+ryKnQzQHKXDC4x92hMIPJVwvPym8C3067Ry6kLHhFOk5IoJjiRmS6P1TT
            48aHipWeiK9G/aLgKTS4UEbUMooAPfeHQXGRfS4fIEQmaaeY0wqQAVYGau2oDn6m
            31SiNEA+NmAmHZFvM2kXf63L58lJASFqRnXquVCw9QIDAQABo4ICPDCCAjgwIQYJ
            KwYBBAGCNxQCBBQeEgBXAGUAYgBTAGUAcgB2AGUAcjATBgNVHSUEDDAKBggrBgEF
            BQcDATAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0OBBYEFGFGkDLulJ3m1Bx3DIa1BosB
            WpOXMCgGA1UdEQQhMB+CCGZpcnN0c2FugglzZWNvbmRzYW6CCHRoaXJkc2FuMB8G
            A1UdIwQYMBaAFN75yc566Q03FdJ4ZQ/6Kn8dohYVMIHEBgNVHR8Egbwwgbkwgbag
            gbOggbCGga1sZGFwOi8vL0NOPUxhYlJvb3RDQTEsQ049Q0ExLENOPUNEUCxDTj1Q
            dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
            aW9uLERDPWNvbnRvc28sREM9Y29tP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/
            YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDCBvAYIKwYBBQUH
            AQEEga8wgawwgakGCCsGAQUFBzAChoGcbGRhcDovLy9DTj1MYWJSb290Q0ExLENO
            PUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1D
            b25maWd1cmF0aW9uLERDPWNvbnRvc28sREM9Y29tP2NBQ2VydGlmaWNhdGU/YmFz
            ZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MA0GCSqGSIb3DQEB
            CwUAA4ICAQBUkvBdMgZsUHDEaVyBuHzALExcEflkvCq1AmJ1U2nixnfcqc5Wb3df
            W+gauW+YbOA9EfQrwPqMXvo0dhsjLn3H5tTWe0VVT5H8pgsdcXS/5cYDjoC6N3pd
            NZGCDN/oHAm8BgcNPPYyG8VDMxR+atp8Iv12nCDGQlpPkANK+nUHR8Nu66l/wDqF
            G8ftnQ7C3mSu4/baAFOAx91rXDbrs1ewrqfcBWxRQn4CZbZs9LMg+NQjrAM8WtQX
            DZd96IMY6m8DeVbIQQiHytpjpQr8aJs6s5Cd5XzRWPXb4lDMOe/4KwpyQAHjtFPY
            mYhUfaInXtna/li9MKLK+j641FnBJv6bjWhw1Jp++wHdjef+1RTtG1hslHQXsH48
            +n+jHZ5A5DKgOYUJWq3NhYvQwtQmDlBNe5aJbTmAFz7qpsPFWjoOqX8RXCE3Mt+R
            EhwMvEGNZHdsgMVXeJsqVssG2FfM7cqcslaUL/vULRWJ6LmJerjmSBRXcEHL6uTe
            IJPSLdUdPx7uvm+P4qpuIuzZ2bdHXqiFbL6yPyWi8lTaApzT/K7Y0Q3oRWYOuThK
            P2l4M+F7l346gaIDDZOXdrSsrPghSgkS4Xp3QtE6NnKq+V0pX2YHnns+JO97hEXt
            2EvKX3TnKnUPPrsl/CffTBpJEsD7xugu6OAn4KnEzzVTNYqzDbYx6g==
            -----END CERTIFICATE-----
            "

    $cerFileWithoutSan = "
            -----BEGIN CERTIFICATE-----
            MIIDBjCCAe6gAwIBAgIQRQyErZRGrolI5DfZCJDaTTANBgkqhkiG9w0BAQsFADAW
            MRQwEgYDVQQDDAtTb21lU2VydmVyMjAeFw0xNzA1MDkxNjI0MTZaFw0xODA1MDkx
            NjQ0MTZaMBYxFDASBgNVBAMMC1NvbWVTZXJ2ZXIyMIIBIjANBgkqhkiG9w0BAQEF
            AAOCAQ8AMIIBCgKCAQEA2x7gR/yQYSiqszd0+e3ZMX2b/mK3XwwEHhoXARoC/Jv/
            rmOmESB6AYabIheGmDv2qUESx6r8KtO4afunVEyoxeThQ8LffgduSo0YIUVgqyg9
            o+HUOaV4MX5cGutgov62MCs+HO2AYcl2QvmbJ9CF/nyGOigoLNOX1pLPHHM1vIFQ
            euBCX8KGK02kgl629QVckiUKrn5bCjboxx7JvSsb2UTcCDjR7x1FcGkxwj069koq
            VdtmwzC3ibYSxQ2UQo1rShol8FPTMkpf8NIZmApY3RGddnAl+r0fznbqqdwzRPjp
            1zXuNwYiG/cL/OOt50TQqCKA7CrD9m8Y3yWKK1ilOQIDAQABo1AwTjAOBgNVHQ8B
            Af8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMB0GA1UdDgQW
            BBSfthQiQydgIs0dXquThRhnkj78HTANBgkqhkiG9w0BAQsFAAOCAQEAuaACrNbE
            clIxVjSsJA4kT7z+ajTD7EmT3iX+h1sOABTuiSjR+fBCF/7AgViK24+xdLzuptCH
            MnoLW7epdP1tRXjs0vb5xwXRsTruwlIzCbvkH8/xkrc6YGw5LzdvxtFPYV+vSsx3
            uUmNlrD7ElllzRVzyGBd2VBm8hCAI0297Ls9zJlWDPYTMpedleO2D9vZBAxg3iY7
            yiMbficleMbVEE3LTNjK6iYuENZ4KOBkOJU936+lqfcVnOFTvWhLJKxTEMZ7XW4k
            pP3LiEhYnnxMfm7OyNHL+MnQhq8OV7tY3pZofPdImEeG13qcV8EBYhefFgsSxQRe
            JqptPVHBXySjMg==
            -----END CERTIFICATE-----
            "

    $cerFileWithAltTemplateName = "
            -----BEGIN CERTIFICATE-----
            MIIDVjCCAj6gAwIBAgIQIA9TO/nfla5FrjJZIiI6nzANBgkqhkiG9w0BAQsFADAW
            MRQwEgYDVQQDDAtzb21lbWFjaGluZTAeFw0xOTAyMTUxNjI3NDVaFw0yMDAyMTUx
            NjQ3NDVaMBYxFDASBgNVBAMMC3NvbWVtYWNoaW5lMIIBIjANBgkqhkiG9w0BAQEF
            AAOCAQ8AMIIBCgKCAQEAuwr0qT/ekYvp4RIHfEqsZyabdWUIR842P/1+t2b0W5bn
            LqxER+mUuBOrbdNcekjQjTnq5rYy1WsIwjeuJ7zgmVINvL8KeYna750M5ngAZsqO
            QoRR9xbQAeht2H1Q9vj/GHbakOKUW45It/0EvZLmF/FJ2+WdIGQMuqQVdr4N+w0f
            DPIVjDCjRLT5USZOHWJGrKYDSaWSf5tEQAp/6RW3JnFkE2biWsYQ3FGZtVgRxjLS
            4+602xnLTyjakQiXBosE0AuW36jiFPeW3WVVF1pdinPpIbtzE0CkoeEwPMfWNJaA
            BfIVmkEKL8HeQGk4kSEvZ/zfNbPr7RfY3S925SeR5QIDAQABo4GfMIGcMA4GA1Ud
            DwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwEwKAYDVR0R
            BCEwH4IIZmlyc3RzYW6CCXNlY29uZHNhboIIdGhpcmRzYW4wIgYJKwYBBAGCNxQC
            BBUeEgBXAGUAYgBTAGUAcgB2AGUAcgAwHQYDVR0OBBYEFNzXV7OE2NNKgKeLPTbT
            +YBIcPJXMA0GCSqGSIb3DQEBCwUAA4IBAQBigwVwGdmE/RekuKY++7oxIrnWkQ0L
            VN+ps5pVLM3+P1XaHdtRUVAHErBuRaqZMTHc4REzSE6PNozrznQJknEnMc6d4y4+
            IZ5pfPl8eyuPs6nBAP5aA3KhC9lW72csjXqe+EJNHfCP0k3AOkBb1A6Cja36h8Ef
            lJiPqE2bRualoz6iqcHftilLCF+8s7q1sW12730PK1BD+gqQo0o8N0fZrXhWU4/I
            0nuuz7F7VEaNcpZD7leBPCiNdsyDkLIfkb2cj4R39Fbs0yuuG6Bv1jQ+adXXprCG
            ZMCE85eAK5et3yur0hVcUHppM6oDPOyoCYnUhDthiO3rwnfRCr/1f3IB
            -----END CERTIFICATE-----
            "

    $cerFileWithAltTemplateInformation = "
            -----BEGIN CERTIFICATE-----
            MIIDazCCAlOgAwIBAgIQJx7ZH+jq5YZLy436X4Li3TANBgkqhkiG9w0BAQsFADAW
            MRQwEgYDVQQDDAtzb21lbWFjaGluZTAeFw0xODA4MDcwOTEwNDVaFw0xOTA4MDcw
            OTMwNDVaMBYxFDASBgNVBAMMC3NvbWVtYWNoaW5lMIIBIjANBgkqhkiG9w0BAQEF
            AAOCAQ8AMIIBCgKCAQEA98nll0sk4LiGTJcbZ+jIY86ongKRNE6CH+LZ0gp4mzUY
            FRufTwmWqqoTjg6Q/Ri+CvofX1CbeaHCSdvI76/vIzF0ij+Y3wGg4Ot8YljbTjsF
            aig3hGaWp+/Q345+O+sTlppwipcmdlp8vS8PNWx+FRbPFyPYSNTHbdFQXGjlz7Lu
            s1gFe9VGbBqditYhvYPJeHjUSBWVDve2vd+E9ECRKssxn3UME74yuRSzEq30ly44
            LPZYRYd8maypJERcMAkRz19bXZ1BNYp1kesxoi0KK7LLodSSzPG01Pls/K51KhZA
            6NuFe14kA+jsAnstWQ2lIofUZxHrQ4IfykmgmP3NmQIDAQABo4G0MIGxMA4GA1Ud
            DwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwEwKAYDVR0R
            BCEwH4IIZmlyc3RzYW6CCXNlY29uZHNhboIIdGhpcmRzYW4wNwYJKwYBBAGCNxUH
            BCowKAYgKwYBBAGCNxUIgt3/eIL6kR6HjYUJhpmDKIHSoVI+ARACAWQCAQUwHQYD
            VR0OBBYEFNt1uNJH8KG4/X0Gzh4rnAPR5lBfMA0GCSqGSIb3DQEBCwUAA4IBAQBI
            MyZvohjsm1wbxJvowp5QrKXvGs8XVl+97zY79h8QqtcZALtIHkZd8rj2Bvkd+qyU
            o01rPj7+LS7HzkdqfmDRUxbAnDclOkUTCMskzxon9CzEsizomFyTq4khWh/p+7fE
            mR2Rq/kA95aupS4Dm7HcncHn89nw9BKcP7WLgIzjRC3ZBzplEGCCL7aKDv66+dv/
            HM2uI47A8kHCFMvaq6O0bjlJfmXvrX8OgVQlRDItiuM+pu9LMkWc0t8U4ekRRQdj
            kVIXdpdvNQmud6JHv3OI0HrjtL7Da1dK7Q8qye3qHBzHwva6SMVbMmFC3ACxukBU
            v+M0WvuaEOEmAQoYaY6K
            -----END CERTIFICATE-----
            "

    $cerBytes = [System.Text.Encoding]::ASCII.GetBytes($cerFileWithSan)
    $cerBytesWithoutSan = [System.Text.Encoding]::ASCII.GetBytes($cerFileWithoutSan)
    $cerBytesWithAltTemplateName = [System.Text.Encoding]::ASCII.GetBytes($cerFileWithAltTemplateName)
    $cerBytesWithAltTemplateInformation = [System.Text.Encoding]::ASCII.GetBytes($cerFileWithAltTemplateInformation)

    $testCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($cerBytes)
    $testCertificateWithoutSan = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($cerBytesWithoutSan)
    $testCertificateWithAltTemplateName = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($cerBytesWithAltTemplateName)
    $testCertificateWithAltTemplateInformation = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($cerBytesWithAltTemplateInformation)

    Describe 'CertificateDsc.Common\Test-CertificatePath' -Tag 'Test-CertificatePath' {
        $null | Set-Content -Path $validPath

        Context 'a single existing file by parameter' {
            $result = Test-CertificatePath -Path $validPath

            It 'Should return true' {
                $result | Should -BeOfType [System.Boolean]
                $result | Should -BeTrue
            }
        }

        Context 'a single missing file by parameter' {
            It 'Should throw an exception' {
                # directories are not valid
                { Test-CertificatePath -Path $invalidPath } | Should -Throw
            }
        }

        Context 'a single missing file by parameter with -Quiet' {
            $result = Test-CertificatePath -Path $invalidPath -Quiet

            It 'Should return false' {
                $result | Should -BeOfType [System.Boolean]
                $result | Should -BeFalse
            }
        }

        Context 'a single existing file by pipeline' {
            $result = $validPath | Test-CertificatePath

            It 'Should return true' {
                $result | Should -BeOfType [System.Boolean]
                $result | Should -BeTrue
            }
        }

        Context 'a single missing file by pipeline' {
            It 'Should throw an exception' {
                # directories are not valid
                { $invalidPath | Test-CertificatePath } | Should -Throw
            }
        }

        Context 'a single missing file by pipeline with -Quiet' {
            $result = $invalidPath | Test-CertificatePath -Quiet

            It 'Should return false' {
                $result | Should -BeOfType [System.Boolean]
                $result | Should -BeFalse
            }
        }
    }

    $getItemPropertyFipsNotSet_Mock = {
        @{
            Enabled = 0
        }
    }

    $getItemPropertyFipsEnabled_Mock = {
        @{
            Enabled = 1
        }
    }

    $getItemPropertyFips_ParameterFilter = {
        $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy'
    }

    Describe 'CertificateDsc.Common\Clear-SupportedHashAlgorithmCache' -Tag 'Clear-SupportedHashAlgorithmCache' {
        Context 'When called and the cache is not null' {
            InModuleScope -ModuleName 'CertificateDsc.Common' -ScriptBlock {
                $script:supportedHashAlgorithms = @( 'Cached Algorithms' )

                It 'Should not have an empty cache' {
                    $script:supportedHashAlgorithms | Should -Not -BeNullOrEmpty
                }

                Clear-SupportedHashAlgorithmCache -Verbose

                It 'Should have an empty cache after clearing' {
                    $script:supportedHashAlgorithms | Should -BeNullOrEmpty
                }
            }

            Context 'When called and the cache is already null' {
                InModuleScope -ModuleName 'CertificateDsc.Common' -ScriptBlock {
                    $script:supportedHashAlgorithms = $null

                    It 'Should have an empty cache' {
                        $script:supportedHashAlgorithms | Should -BeNullOrEmpty
                    }

                    Clear-SupportedHashAlgorithmCache -Verbose

                    It 'Should have an empty cache after clearing' {
                        $script:supportedHashAlgorithms | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-SupportedHashAlgorithms' -Tag 'Get-SupportedHashAlgorithms' {
        Context 'When FIPS not set' {
            Clear-SupportedHashAlgorithmCache -Verbose
            Mock -CommandName Get-ItemProperty -MockWith $getItemPropertyFipsNotSet_Mock -ParameterFilter $getItemPropertyFips_ParameterFilter

            It 'Should return at least one algorithm' {
                $result = Get-SupportedHashAlgorithms -Verbose
                $result.Count | Should -BeGreaterThan 0
            }
        }

        Context 'When FIPS is enabled' {
            Clear-SupportedHashAlgorithmCache -Verbose
            Mock -CommandName Get-ItemProperty -MockWith $getItemPropertyFipsEnabled_Mock -ParameterFilter $getItemPropertyFips_ParameterFilter

            It 'Should return at least one algorithm' {
                $result = Get-SupportedHashAlgorithms -Verbose
                $result.Count | Should -BeGreaterThan 0
            }
        }
    }

    Describe 'CertificateDsc.Common\Test-Thumbprint' -Tag 'Test-Thumbprint' {
        Context 'When FIPS not set' {
            Clear-SupportedHashAlgorithmCache -Verbose
            Mock -CommandName Get-ItemProperty -MockWith $getItemPropertyFipsNotSet_Mock -ParameterFilter $getItemPropertyFips_ParameterFilter

            Context 'When a single valid thumbrpint by parameter is passed' {
                It 'Should return true' {
                    $result = Test-Thumbprint -Thumbprint $validThumbprint -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeTrue
                }
            }

            Context 'When a single invalid thumbprint by parameter is passed' {
                It 'Should throw an exception' {
                    { Test-Thumbprint -Thumbprint $invalidThumbprint -Verbose } | Should -Throw
                }
            }

            Context 'When a single invalid thumbprint by parameter with -Quiet is passed' {
                It 'Should return false' {
                    $result = Test-Thumbprint $invalidThumbprint -Quiet -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeFalse
                }
            }

            Context 'When a single valid thumbprint by pipeline is passed' {
                It 'Should return true' {
                    $result = $validThumbprint | Test-Thumbprint -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeTrue
                }
            }

            Context 'When a single invalid thumbprint by pipeline is passed' {
                It 'Should throw an exception' {
                    { $invalidThumbprint | Test-Thumbprint -Verbose  } | Should -Throw
                }
            }

            Context 'When a single invalid thumbprint by pipeline with -Quiet is passed' {
                It 'Should return false' {
                    $result = $invalidThumbprint | Test-Thumbprint -Quiet -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeFalse
                }
            }
        }

        Context 'When FIPS is enabled' {
            Clear-SupportedHashAlgorithmCache -Verbose
            Mock -CommandName Get-ItemProperty -MockWith $getItemPropertyFipsEnabled_Mock -ParameterFilter $getItemPropertyFips_ParameterFilter

            Context 'When a single valid FIPS thumbrpint by parameter is passed' {
                It 'Should return true' {
                    $result = Test-Thumbprint -Thumbprint $validFipsThumbprint -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeTrue
                }
            }

            Context 'When a single invalid FIPS thumbprint by parameter is passed' {
                It 'Should throw an exception' {
                    { Test-Thumbprint -Thumbprint $invalidFipsThumbprint -Verbose } | Should -Throw
                }
            }

            Context 'When a single invalid FIPS thumbprint by parameter with -Quiet is passed' {
                It 'Should return false' {
                    $result = Test-Thumbprint $invalidFipsThumbprint -Quiet -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeFalse
                }
            }

            Context 'When a single valid FIPS thumbprint by pipeline is passed' {
                It 'Should return true' {
                    $result = $validFipsThumbprint | Test-Thumbprint -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeTrue
                }
            }

            Context 'When a single invalid FIPS thumbprint by pipeline is passed' {
                It 'Should throw an exception' {
                    { $invalidFipsThumbprint | Test-Thumbprint -Verbose } | Should -Throw
                }
            }

            Context 'When a single invalid FIPS thumbprint by pipeline with -Quiet is passed' {
                It 'Should return false' {
                    $result =  $invalidFipsThumbprint | Test-Thumbprint -Quiet -Verbose
                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeFalse
                }
            }
        }
    }

    Describe 'CertificateDsc.Common\Find-Certificate' -Tag 'Find-Certificate' {
        # Generate the Valid certificate for testing but remove it from the store straight away
        $certificateDNSNames = @('www.fabrikam.com', 'www.contoso.com')
        $certificateDNSNamesReverse = @('www.contoso.com', 'www.fabrikam.com')
        $certificateDNSNamesNoMatch = $certificateDNSNames + @('www.nothere.com')
        $certificateKeyUsage = @('DigitalSignature', 'DataEncipherment')
        $certificateKeyUsageReverse = @('DataEncipherment', 'DigitalSignature')
        $certificateKeyUsageNoMatch = $certificateKeyUsage + @('KeyEncipherment')
        <#
            To set Enhanced Key Usage, we must use OIDs:
            Enhanced Key Usage. 2.5.29.37
            Client Authentication. 1.3.6.1.5.5.7.3.2
            Server Authentication. 1.3.6.1.5.5.7.3.1
            Microsoft EFS File Recovery. 1.3.6.1.4.1.311.10.3.4.1
        #>
        $certificateEKU = @('Server Authentication', 'Client authentication')
        $certificateEKUOID = '2.5.29.37={text}1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.1'
        $certificateEKUReverse = @('Client authentication','Server Authentication')
        $certificateEKUNoMatch = $certificateEKU + @('Encrypting File System')
        $certificateSubject = 'CN=contoso, DC=com'
        $certificateFriendlyName = 'Contoso Test Cert'
        $validCertificate = New-SelfSignedCertificate `
            -Subject $certificateSubject `
            -KeyUsage $certificateKeyUsage `
            -KeySpec 'KeyExchange' `
            -TextExtension $certificateEKUOID `
            -DnsName $certificateDNSNames `
            -FriendlyName $certificateFriendlyName `
            -CertStoreLocation 'cert:\CurrentUser' `
            -KeyExportPolicy Exportable
        # Pull the generated certificate from the store so we have the friendlyname
        $validThumbprint = $validCertificate.Thumbprint
        $validCertificate = Get-Item -Path "cert:\CurrentUser\My\$validThumbprint"
        Remove-Item -Path $validCertificate.PSPath -Force

        # Generate the Expired certificate for testing but remove it from the store straight away
        $expiredCertificate = New-SelfSignedCertificate `
            -Subject $certificateSubject `
            -KeyUsage $certificateKeyUsage `
            -KeySpec 'KeyExchange' `
            -TextExtension $certificateEKUOID `
            -DnsName $certificateDNSNames `
            -FriendlyName $certificateFriendlyName `
            -NotBefore ((Get-Date) - (New-TimeSpan -Days 2)) `
            -NotAfter ((Get-Date) - (New-TimeSpan -Days 1)) `
            -CertStoreLocation 'cert:\CurrentUser' `
            -KeyExportPolicy Exportable
        # Pull the generated certificate from the store so we have the friendlyname
        $expiredThumbprint = $expiredCertificate.Thumbprint
        $expiredCertificate = Get-Item -Path "cert:\CurrentUser\My\$expiredThumbprint"
        Remove-Item -Path $expiredCertificate.PSPath -Force

        $noCertificateThumbprint = '1111111111111111111111111111111111111111'

        # Dynamic mock content for Get-ChildItem
        $mockGetChildItem = {
            switch ( $Path )
            {
                'cert:\LocalMachine\My'
                {
                    return @( $validCertificate )
                }

                'cert:\LocalMachine\NoCert'
                {
                    return @()
                }

                'cert:\LocalMachine\TwoCerts'
                {
                    return @( $expiredCertificate, $validCertificate )
                }

                'cert:\LocalMachine\Expired'
                {
                    return @( $expiredCertificate )
                }

                default
                {
                    throw 'mock called with unexpected value {0}' -f $Path
                }
            }
        }

        BeforeEach {
            Mock `
                -CommandName Test-Path `
                -MockWith { $true }

            Mock `
                -CommandName Get-ChildItem `
                -MockWith $mockGetChildItem
        }

        Context 'Thumbprint only is passed and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -Thumbprint $validThumbprint } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Thumbprint only is passed and matching certificate does not exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -Thumbprint $noCertificateThumbprint } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and matching certificate does not exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName 'Does Not Exist' } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Subject only is passed and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -Subject $certificateSubject } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Subject only is passed and matching certificate does not exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -Subject 'CN=Does Not Exist' } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Issuer only is passed and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -Issuer $certificateSubject } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Issuer only is passed and matching certificate does not exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -Issuer 'CN=Does Not Exist' } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certificateDNSNames } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed in reversed order and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certificateDNSNamesReverse } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed with only one matching DNS name and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certificateDNSNames[0] } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'DNSName only is passed but an entry is missing and matching certificate does not exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -DnsName $certificateDNSNamesNoMatch } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certificateKeyUsage } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed in reversed order and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certificateKeyUsageReverse } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed with only one matching DNS name and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certificateKeyUsage[0] } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'KeyUsage only is passed but an entry is missing and matching certificate does not exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -KeyUsage $certificateKeyUsageNoMatch } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKU } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed in reversed order and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKUReverse } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed with only one matching DNS name and matching certificate exists' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKU[0] } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'EnhancedKeyUsage only is passed but an entry is missing and matching certificate does not exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -EnhancedKeyUsage $certificateEKUNoMatch } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'Thumbprint only is passed and matching certificate does not exist in the store' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -Thumbprint $validThumbprint -Store 'NoCert' } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and both valid and expired certificates exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName -Store 'TwoCerts' } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $validThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and only expired certificates exist' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName -Store 'Expired' } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }

        Context 'FriendlyName only is passed and only expired certificates exist but allowexpired passed' {
            It 'Should not throw exception' {
                { $script:result = Find-Certificate -FriendlyName $certificateFriendlyName -Store 'Expired' -AllowExpired:$true } | Should -Not -Throw
            }

            It 'Should return expected certificate' {
                $script:result.Thumbprint | Should -Be $expiredThumbprint
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
            }
        }
    }

    Describe 'CertificateDsc.Common\Find-CertificateAuthority' -Tag 'Find-CertificateAuthority' {
        Context 'Function is executed with domain connectivity' {
            Mock `
                -CommandName Get-CdpContainer `
                -MockWith {
                [CmdletBinding()]
                param
                (
                    [Parameter()]
                    $DomainName
                )

                return New-Object -TypeName psobject -Property @{
                    Children = @(
                        @{
                            distinguishedName = 'CN=CA1,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com'
                            Children          = @{
                                distinguishedName = 'CN=LabRootCA1,CN=CA1,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com'
                            }
                        }
                    )
                }
            }

            Mock `
                -CommandName Test-CertificateAuthority `
                -ParameterFilter { $CARootName -eq 'LabRootCA1' -and $CAServerFQDN -eq 'CA1' } `
                -MockWith { return $true }

            It 'Should not throw exception' {
                $script:result = Find-CertificateAuthority -DomainName contoso.com -Verbose
            }

            It 'Should return the expected CA' {
                $script:result.CARootName | Should -Be 'LabRootCA1'
                $script:result.CAServerFQDN | Should -Be 'CA1'
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-CdpContainer -Exactly -Times 1
                Assert-MockCalled -CommandName Test-CertificateAuthority -Exactly -Times 1
            }
        }

        Context 'Function is executed with domain connectivity but CA is uncontactable' {
            Mock `
                -CommandName Get-CdpContainer `
                -MockWith {
                [CmdletBinding()]
                param
                (
                    [Parameter()]
                    $DomainName
                )

                return New-Object -TypeName psobject -Property @{
                    Children = @(
                        @{
                            distinguishedName = 'CN=CA1,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com'
                            Children          = @{
                                distinguishedName = 'CN=LabRootCA1,CN=CA1,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com'
                            }
                        }
                    )
                }
            }

            Mock `
                -CommandName Test-CertificateAuthority `
                -ParameterFilter { $CARootName -eq 'LabRootCA1' -and $CAServerFQDN -eq 'CA1' } `
                -MockWith { return $false }

            $errorRecord = Get-InvalidOperationRecord `
                -Message ($LocalizedData.NoCaFoundError)

            It 'Should throw NoCaFoundError exception' {
                { Find-CertificateAuthority -DomainName contoso.com -Verbose } | Should -Throw $errorRecord
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-CdpContainer -Exactly -Times 1
                Assert-MockCalled -CommandName Test-CertificateAuthority -Exactly -Times 1
            }
        }

        Context 'Function is executed without domain connectivity' {
            Mock `
                -CommandName Get-CdpContainer `
                -MockWith {
                [CmdletBinding()]
                param
                (
                    [Parameter()]
                    $DomainName
                )

                New-InvalidOperationException `
                    -Message ($LocalizedData.DomainNotJoinedError)
            }

            Mock `
                -CommandName Test-CertificateAuthority `
                -ParameterFilter { $CARootName -eq 'LabRootCA1' -and $CAServerFQDN -eq 'CA1' } `
                -MockWith { return $false }

            $errorRecord = Get-InvalidOperationRecord `
                -Message ($LocalizedData.DomainNotJoinedError)

            It 'Should throw DomainNotJoinedError exception' {
                { Find-CertificateAuthority -DomainName 'somewhere.overtherainbow' -Verbose } | Should -Throw $errorRecord
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-CdpContainer -Exactly -Times 1
                Assert-MockCalled -CommandName Test-CertificateAuthority -Exactly -Times 0
            }
        }
    }

    Describe 'CertificateDsc.Common\Test-CertificateAuthority' -Tag 'Test-CertificateAuthority' {
        Mock `
            -CommandName New-Object `
            -ParameterFilter { $TypeName -eq 'System.Diagnostics.ProcessStartInfo' } `
            -MockWith {
            $retObj = New-Object -TypeName psobject -Property @{
                FileName               = ''
                Arguments              = ''
                RedirectStandardError  = $false
                RedirectStandardOutput = $true
                UseShellExecute        = $false
                CreateNoWindow         = $true
            }

            return $retObj
        }

        Context 'Function is executed with CA online' {
            Mock `
                -CommandName New-Object `
                -ParameterFilter {
                    $TypeName -eq 'System.Diagnostics.Process'
                } `
                -MockWith {
                    $retObj = New-Object -TypeName psobject -Property @{
                        StartInfo      = $null
                        ExitCode       = 0
                        StandardOutput = New-Object -TypeName psobject |
                            Add-Member -MemberType ScriptMethod -Name ReadToEnd -Value {
                                return @"
Connecting to LabRootCA1\CA1 ...
Server "CA1" ICertRequest2 interface is alive (32ms)
CertUtil: -ping command completed successfully.
"@
                        } -PassThru
                    }

                $retObj |
                    Add-Member -MemberType ScriptMethod -Name Start -Value { } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }

                return $retObj
            }

            It 'Should not throw exception' {
                $script:result = Test-CertificateAuthority `
                    -CARootName 'LabRootCA1' `
                    -CAServerFQDN 'CA1' `
                    -Verbose
            }

            It 'Should return true' {
                $script:result | Should -BeTrue
            }

            It 'Should call expected mocks' {
                Assert-MockCalled `
                    -CommandName New-Object `
                    -ParameterFilter { $TypeName -eq 'System.Diagnostics.ProcessStartInfo' } `
                    -Exactly -Times 1

                Assert-MockCalled `
                    -CommandName New-Object `
                    -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' } `
                    -Exactly -Times 1
            }
        }

        Context 'Function is executed with CA offline' {
            Mock `
                -CommandName New-Object `
                -ParameterFilter {
                    $TypeName -eq 'System.Diagnostics.Process'
                } `
                -MockWith {
                    $retObj = New-Object -TypeName psobject -Property @{
                    StartInfo      = $null
                    ExitCode       = -2147024809
                    StandardOutput = New-Object -TypeName psobject |
                        Add-Member -MemberType ScriptMethod -Name ReadToEnd -Value {
                            return @"
Connecting to LabRootCA1\CA2 ...
Server could not be reached: The parameter is incorrect. 0x80070057 (WIN32: 87 ERROR_INVALID_PARAMETER) -- (31ms)

CertUtil: -ping command FAILED: 0x80070057 (WIN32: 87 ERROR_INVALID_PARAMETER)
CertUtil: The parameter is incorrect.
"@
                        } -PassThru
                 }

                $retObj |
                    Add-Member -MemberType ScriptMethod -Name Start -Value { } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }

                return $retObj
            }

            It 'Should not throw exception' {
                $script:result = Test-CertificateAuthority `
                    -CARootName 'LabRootCA1' `
                    -CAServerFQDN 'CA2' `
                    -Verbose
            }

            It 'Should return false' {
                $script:result | Should -BeFalse
            }

            It 'Should call expected mocks' {
                Assert-MockCalled `
                    -CommandName New-Object `
                    -ParameterFilter { $TypeName -eq 'System.Diagnostics.ProcessStartInfo' } `
                    -Exactly -Times 1

                Assert-MockCalled `
                    -CommandName New-Object `
                    -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' } `
                    -Exactly -Times 1
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateTemplateName' -Tag 'Get-CertificateTemplateName' {
        Mock -CommandName Get-CertificateTemplatesFromActiveDirectory -MockWith {
            @(
                [PSCustomObject] @{
                    'Name'                    = 'WebServer'
                    'DisplayName'             = 'Web Server'
                    'mspki-cert-template-oid' = '1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.1.16'
                }
            )
        }

        Context 'When a certificate with the extension "Certificate Template Name" is used' {
            It 'Should return the template name' {
                Get-CertificateTemplateName -Certificate $testCertificate | Should -Be 'WebServer'
            }
        }

        Context 'When a certificate with the extension "Certificate Template Information" is used.' {
            It 'Should return the template name when there is no display name' {
                Get-CertificateTemplateName -Certificate $testCertificateWithAltTemplateInformation | Should -Be 'WebServer'
            }

            Mock -CommandName Get-CertificateTemplateExtensionText -MockWith {
                @'
Template=Web Server(1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.1.16)
Major Version Number=100
Minor Version Number=5
'@
            }

            It 'Should return the template name when there is a display name' {
                Get-CertificateTemplateName -Certificate $testCertificateWithAltTemplateInformation | Should -Be 'WebServer'
            }
        }

        Context 'When a certificate with no template name is used' {
            It 'Should return null' {
                Get-CertificateTemplateName -Certificate $testCertificateWithoutSan | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateTemplatesFromActiveDirectory' -Tag 'Get-CertificateTemplatesFromActiveDirectory' {
        $MockSearchResults = @(
            @{
                Properties = @(
                    @{
                        Name  = 'name'
                        Value = 'MockData1'
                    }
                    @{
                        Name  = 'displayName'
                        Value = 'Mock Data 1'
                    }
                )
            }
            @{
                Properties = @(
                    @{
                        Name  = 'name'
                        Value = 'MockData2'
                    }
                    @{
                        Name  = 'displayName'
                        Value = 'Mock Data 2'
                    }
                )
            }
            @{
                Properties = @(
                    @{
                        Name  = 'name'
                        Value = 'MockData3'
                    }
                    @{
                        Name  = 'displayName'
                        Value = 'Mock Data 3'
                    }
                )
            }
        )

        $newObject_parameterFilter = {
            $TypeName -eq 'DirectoryServices.DirectorySearcher'
        }

        $newObject_mock = {
            [PSCustomObject] @{
                Filter     = $null
                SearchRoot = $null
            } | Add-Member -MemberType ScriptMethod -Name FindAll -Value {
                $MockSearchResults
            } -PassThru
        }

        Mock -CommandName New-Object -ParameterFilter $newObject_parameterFilter -MockWith $newObject_mock
        Mock -CommandName Get-DirectoryEntry

        Context 'When certificate templates are retrieved from Active Directory successfully' {
            It 'Should get 3 mocked search results' {
                $SearchResults = Get-CertificateTemplatesFromActiveDirectory

                Assert-MockCalled -CommandName Get-DirectoryEntry -Exactly -Times 1
                Assert-MockCalled -CommandName New-Object         -Exactly -Times 1

                $SearchResults.Count | Should -Be 3
            }
        }

        Context 'When certificate templates are not retrieved from Active Directory successfully' {
            Mock -CommandName Get-DirectoryEntry -MockWith {
                throw 'Mock Function Failure'
            }

            It 'Should display a warning message' {
                $Message = $LocalizedData.ActiveDirectoryTemplateSearch

                (Get-CertificateTemplatesFromActiveDirectory -Verbose 3>&1).Message | Should -Be $Message
            }

            It 'Should display a verbose message' {
                $Message = 'Mock Function Failure'

                (Get-CertificateTemplatesFromActiveDirectory -Verbose 4>&1).Message | Should -Be $Message
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateTemplateInformation' -Tag 'Get-CertificateTemplateInformation' {
        $mockADTemplates = @(
            @{
                'Name'                    = 'DisplayName1'
                'DisplayName'             = 'Display Name 1'
                'msPKI-Cert-Template-OID' = '1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.3384218.1234567'
            }
            @{
                'Name'                    = 'DisplayName2'
                'DisplayName'             = 'Display Name 2'
                'msPKI-Cert-Template-OID' = '1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.3384218.2345678'
            }
        )

        $certificateTemplateExtensionFormattedText1 = @'
Template=Display Name 1(1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.3384218.1234567)
Major Version Number=100
Minor Version Number=5
'@

        $certificateTemplateExtensionFormattedText1NoDisplayName = @'
Template=1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.3384218.1234567
Major Version Number=100
Minor Version Number=5
'@

        $certificateTemplateExtensionFormattedText2 = @'
Template=Display Name 2(1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.3384218.2345678)
Major Version Number=100
Minor Version Number=5
'@

        $certificateTemplateExtensionFormattedText2NoDisplayName = @'
Template=1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.3384218.2345678
Major Version Number=100
Minor Version Number=5
'@

        $certificateTemplateExtensionFormattedText3 = @'
Template=Display Name 3(1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.3384218.3456789)
Major Version Number=100
Minor Version Number=5
'@
        $RegexTemplatePattern = '^\w+=(?<Name>.*)\((?<Oid>[\.\d]+)\)'

        Mock -CommandName Get-CertificateTemplatesFromActiveDirectory -MockWith { $mockADTemplates }

        Context 'When FormattedTemplate contains a Template OID with a Template Display Name' {

            It 'Should return the Template Name "DisplayName1"' {
                $params = @{
                    FormattedTemplate = $certificateTemplateExtensionFormattedText1
                }

                (Get-CertificateTemplateInformation @params).Name | Should -Be 'DisplayName1'
            }

            It 'Should return the Template Name "DisplayName2"' {
                $params = @{
                    FormattedTemplate = $certificateTemplateExtensionFormattedText2
                }

                (Get-CertificateTemplateInformation @params).Name | Should -Be 'DisplayName2'
            }

            It 'Should write a warning when there is no match in Active Directory' {
                $templateValues = [Regex]::Match($certificateTemplateExtensionFormattedText3, $RegexTemplatePattern)

                $templateText = '{0}({1})' -f $templateValues.Groups['Name'].Value, $templateValues.Groups['Oid'].Value

                $warningMessage = $localizedData.TemplateNameResolutionError -f $templateText

                $params = @{
                    FormattedTemplate = $certificateTemplateExtensionFormattedText3
                }

                (Get-CertificateTemplateInformation @params 3>&1)[0].Message | Should -Be $warningMessage
            }
        }

        Context 'When FormattedTemplate contains a Template OID without a Template Display Name' {
            It 'Should return the Template Name "DisplayName1"' {
                $params = @{
                    FormattedTemplate = $certificateTemplateExtensionFormattedText1NoDisplayName
                }

                (Get-CertificateTemplateInformation @params).Name | Should -Be 'DisplayName1'
            }

            It 'Should return the Template Name "DisplayName2"' {
                $params = @{
                    FormattedTemplate = $certificateTemplateExtensionFormattedText2NoDisplayName
                }

                (Get-CertificateTemplateInformation @params).Name | Should -Be 'DisplayName2'
            }

            It 'Should write a warning when there is no match in Active Directory' {
                $templateValues = [Regex]::Match($certificateTemplateExtensionFormattedText3, $RegexTemplatePattern)

                $templateText = '{0}({1})' -f $templateValues.Groups['Name'].Value, $templateValues.Groups['Oid'].Value

                $warningMessage = $localizedData.TemplateNameResolutionError -f $templateText

                $params = @{
                    FormattedTemplate = $certificateTemplateExtensionFormattedText3
                }

                (Get-CertificateTemplateInformation @params 3>&1)[0].Message | Should -Be $warningMessage
            }
        }

        Context 'When FormattedTemplate contains a the Template Name' {
            It 'Should return the FormattedText' {
                $templateName = 'TemplateName'

                (Get-CertificateTemplateInformation -FormattedTemplate $templateName).Name | Should -Be $templateName
            }

            It 'Should return the FormattedText Without a Trailing Carriage Return' {
                $templateName = 'TemplateName' + [Char]13

                (Get-CertificateTemplateInformation -FormattedTemplate $templateName).Name | Should -Be $templateName.TrimEnd([Char]13)
            }
        }

        Context 'When FormattedTemplate does not contain a recognised format' {
            It 'Should write a warning when there is no match in Active Directory' {
                $formattedTemplate = 'Unrecognized Format'

                $warningMessage = $localizedData.TemplateNameNotFound -f $formattedTemplate

                (Get-CertificateTemplateInformation -FormattedTemplate $formattedTemplate 3>&1)[0].Message | Should -Be $warningMessage
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateExtension' -Tag 'Get-CertificateExtension' {
        Context 'When a certificate contains an extension that matches the Oid parameter and First is not specified' {
            It 'Should return the extension with Oid ''2.5.29.17''' {
                $extension = Get-CertificateExtension -Certificate $testCertificate -Oid '2.5.29.17'
                $extension | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Extension]
                $extension | Should -HaveCount 1
                $extension.Oid.Value | Should -Be '2.5.29.17'
            }
        }

        Context 'When a certificate does not contain an extension that matches the Oid parameter and First is not specified' {
            It 'Should return no extension' {
                $extension = Get-CertificateExtension -Certificate $testCertificate -Oid '2.9.9.9'
                $extension | Should -BeNullOrEmpty
            }
        }

        Context 'When a certificate does not contain an extension that matches the Oid parameter and First is set to 2' {
            It 'Should return no extension' {
                $extension = Get-CertificateExtension -Certificate $testCertificate -Oid '2.9.9.9' -First 2
                $extension | Should -BeNullOrEmpty
            }
        }

        Context 'When a certificate contains an extension that matches only one of the Oid parameter values and First is not specified' {
            It 'Should return the extension with Oid ''2.5.29.17''' {
                $extension = Get-CertificateExtension -Certificate $testCertificate -Oid '2.5.29.17', '2.9.9.9'
                $extension | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Extension]
                $extension | Should -HaveCount 1
                $extension.Oid.Value | Should -Be '2.5.29.17'
            }
        }

        Context 'When a certificate contains an extension that matches both of the Oid parameter values and First is not specified' {
            It 'Should return the extension with Oid ''2.5.29.17''' {
                $extension = Get-CertificateExtension -Certificate $testCertificate -Oid '2.5.29.17', '2.5.29.31'
                $extension | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Extension]
                $extension | Should -HaveCount 1
                $extension.Oid.Value | Should -Contain '2.5.29.17'
            }
        }

        Context 'When a certificate contains an extension that matches both of the Oid parameter values but First is set to 2' {
            It 'Should return the extension with Oid ''2.5.29.17'' and ''2.5.29.31''' {
                $extension = Get-CertificateExtension -Certificate $testCertificate -Oid '2.5.29.17', '2.5.29.31' -First 2
                $extension | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Extension]
                $extension | Should -HaveCount 2
                $extension.Oid.Value | Should -Contain '2.5.29.17'
                $extension.Oid.Value | Should -Contain '2.5.29.31'
            }
        }

        Context 'When a certificate contains an extension that matches both of the Oid parameter values but First is set to 3' {
            It 'Should return the extension with Oid ''2.5.29.17'' and ''2.5.29.31''' {
                $extension = Get-CertificateExtension -Certificate $testCertificate -Oid '2.5.29.17', '2.5.29.31' -First 3
                $extension | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Extension]
                $extension | Should -HaveCount 2
                $extension.Oid.Value | Should -Contain '2.5.29.17'
                $extension.Oid.Value | Should -Contain '2.5.29.31'
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateTemplateExtensionText' -Tag 'Get-CertificateTemplateExtensionText' {
        Context 'When a certificate contains Certificate Template Name extension' {
            It 'Should return the Name of the Certificate Template' {
                $params = @{
                    Certificate = $testCertificateWithAltTemplateName
                }

                # Template Names have a trailing carriage return and linefeed.
                Get-CertificateTemplateExtensionText @params | Should -Be ('WebServer' + [Char]13 + [Char]10)
            }
        }

        Context 'When a certificate contains Certificate Template Information extension' {
            It 'Should return the Oid, Major and Minor Version of the Certificate Template' {
                $CertificateTemplateInformation = @'
Template=1.3.6.1.4.1.311.21.8.5734392.6195358.14893705.12992936.3444946.62.1.16
Major Version Number=100
Minor Version Number=5

'@

                $params = @{
                    Certificate = $testCertificateWithAltTemplateInformation
                }

                # Template Names have a trailing carriage return and linefeed.
                Get-CertificateTemplateExtensionText @params | Should -Be $CertificateTemplateInformation
            }
        }

        Context 'When a certificate does not contain a Certificate Template extension' {
            It 'Should not return anything' {
                $params = @{
                    Certificate = $testCertificateWithoutSan
                }

                # Template Names have a trailing carriage return and linefeed.
                Get-CertificateTemplateExtensionText @params | Should -Be $null
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateSubjectAlternativeName' -Tag 'Get-CertificateSubjectAlternativeName' {
        Context 'When a certificate with a SAN is used' {
            It 'Should return the SAN' {
                Get-CertificateSubjectAlternativeName -Certificate $testCertificate | Should -Be 'firstsan'
            }
        }

        Context 'When a certificate without SAN is used' {
            It 'Should return null' {
                Get-CertificateSubjectAlternativeName -Certificate $testCertificateWithoutSan | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateSubjectAlternativeNameList' -Tag 'Get-CertificateSubjectAlternativeNameList' {
        Context 'When a certificate with a Subject Alternative Name is used' {
            It 'Should return the list of Subject Alternative Name entries' {
                $result = Get-CertificateSubjectAlternativeNameList -Certificate $testCertificate
                $result | Should -HaveCount 3
                $result | Should -Contain 'DNS Name=firstsan'
                $result | Should -Contain 'DNS Name=secondsan'
                $result | Should -Contain 'DNS Name=thirdsan'
            }
        }

        Context 'When a certificate without Subject Alternative Name is used' {
            It 'Should return null' {
                $result = Get-CertificateSubjectAlternativeNameList -Certificate $testCertificateWithoutSan
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'CertificateDsc.Common\Test-CommandExists' -Tag 'Test-CommandExists' {
        $testCommandName = 'TestCommandName'

        Mock -CommandName 'Get-Command' -MockWith { return $Name }

        Context 'When Get-Command returns' {
            It 'Should not throw exception' {
                { $null = Test-CommandExists -Name $testCommandName } | Should -Not -Throw
            }

            It 'Should retrieve the command with the specified name' {
                $getCommandParameterFilter = {
                    return $Name -eq $testCommandName
                }

                Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly -Times 1 -Scope 'Context'
            }

            It 'Should return true' {
                Test-CommandExists -Name $testCommandName | Should -BeTrue
            }
        }

        Context 'When Get-Command returns null' {
            Mock -CommandName 'Get-Command' -MockWith { return $null }

            It 'Should not throw exception' {
                { $null = Test-CommandExists -Name $testCommandName } | Should -Not -Throw
            }

            It 'Should retrieve the command with the specified name' {
                $getCommandParameterFilter = {
                    return $Name -eq $testCommandName
                }

                Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly -Times 1 -Scope 'Context'
            }

            It 'Should return false' {
                Test-CommandExists -Name $testCommandName | Should -BeFalse
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateStorePath' -Tag 'Get-CertificateStorePath' {
        Context 'When called with a Store and Location that exists' {
            Mock -CommandName Test-Path -MockWith { $true }

            It 'Should not throw exception' {
                {
                    $script:getCertificateStorePathResult = Get-CertificateStorePath `
                        -Location 'LocalMachine' `
                        -Store 'TestStore'
                } | Should -Not -Throw
            }

            It 'Should return the expected path' {
                $script:getCertificateStorePathResult = 'Cert:\LocalMachine\TestStore'
            }
        }

        Context 'When called with a Store and Location that does not exist' {
            Mock -CommandName Test-Path -MockWith { $false }

            It 'Should throw expected exception' {
                {
                    Get-CertificateStorePath `
                        -Location 'LocalMachine' `
                        -Store 'TestStore'
                } | Should -Throw ($script:localizedData.CertificateStoreNotFoundError -f 'Cert:\LocalMachine\TestStore')
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificatePath' -Tag 'Get-CertificatePath' {
        Context 'When called with Thumbprint, Store and Location' {
            Mock -CommandName Test-Path -MockWith { $true }

            It 'Should not throw exception' {
                {
                    $script:getCertificatePathResult = Get-CertificatePath `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore'
                } | Should -Not -Throw
            }

            It 'Should return the expected path' {
                $script:getCertificateStorePathResult = 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a2057'
            }
        }
    }

    Describe 'CertificateDsc.Common\Get-CertificateFromCertificateStore' -Tag 'Get-CertificateFromCertificateStore' {
        Context 'When the certificate exists in the store' {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem -MockWith {
                @(
                    [PSCustomObject] @{
                        PSPath = 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                    }
                )
            }

            It 'Should not throw exception' {
                {
                    $script:getCertificateFromCertificateStoreResult = Get-CertificateFromCertificateStore `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore' `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should return the expected certificate' {
                $script:getCertificateFromCertificateStoreResult.PSPath | Should -Be 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                } -Exactly -Times 1
            }
        }

        Context 'When the certificate does not exist in the store' {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem

            It 'Should not throw exception' {
                {
                    $script:getCertificateFromCertificateStoreResult = Get-CertificateFromCertificateStore `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore' `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should not return any certificates' {
                $script:getCertificateFromCertificateStoreResult.PSPath | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                } -Exactly -Times 1
            }
        }
    }

    Describe 'CertificateDsc.Common\Remove-CertificateFromCertificateStore' -Tag 'Remove-CertificateFromCertificateStore' {
        Context 'When the certificate exists in the store' {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem -MockWith {
                @(
                    [PSCustomObject] @{
                        PSPath = 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                    }
                )
            }
            Mock -CommandName Remove-Item

            It 'Should not throw exception' {
                {
                    Remove-CertificateFromCertificateStore `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore' `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Remove-Item -ParameterFilter {
                    $Path -eq 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578' `
                        -and $Force -eq $true
                } -Exactly -Times 1
            }
        }

        Context 'When the certificate exists in the store twice' {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem -MockWith {
                @(
                    [PSCustomObject] @{
                        PSPath = 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                    },
                    [PSCustomObject] @{
                        PSPath = 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                    }
                )
            }
            Mock -CommandName Remove-Item

            It 'Should not throw exception' {
                {
                    Remove-CertificateFromCertificateStore `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore' `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Remove-Item -ParameterFilter {
                    $Path -eq 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578' `
                        -and $Force -eq $true
                } -Exactly -Times 2
            }
        }

        Context 'When the certificate does not exist in the store' {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem
            Mock -CommandName Remove-Item

            It 'Should not throw exception' {
                {
                    Remove-CertificateFromCertificateStore `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore' `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 0
            }
        }
    }

    Describe 'CertificateDsc.Common\Set-CertificateFriendlyNameInCertificateStore' -Tag 'Set-CertificateFriendlyNameInCertificateStore' {
        Context 'When the certificate exists in the store' {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem -MockWith {
                @(
                    [PSCustomObject] @{
                        PSPath       = 'Microsoft.PowerShell.Security\Certificate::LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                        FriendlyName = 'Nothing'
                    }
                )
            }

            It 'Should not throw exception' {
                {
                    Set-CertificateFriendlyNameInCertificateStore `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore' `
                        -FriendlyName 'New Name' `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                } -Exactly -Times 1
            }
        }

        Context 'When the certificate does not exist in the store' {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-ChildItem

            It 'Should not throw exception' {
                {
                    Set-CertificateFriendlyNameInCertificateStore `
                        -Thumbprint '627b268587e95099e72aab831a81f887d7a20578' `
                        -Location 'LocalMachine' `
                        -Store 'TestStore' `
                        -FriendlyName 'New Name' `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'Cert:\LocalMachine\TestStore\627b268587e95099e72aab831a81f887d7a20578'
                } -Exactly -Times 1
            }
        }
    }
}
