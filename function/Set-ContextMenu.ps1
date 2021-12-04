Function Set-ContextMenu{
    Param(
        $Model,
        [System.Windows.Media.Media3D.Point3D]$Position
    )
    Switch($Model){
        "Floor"{
                $contextmenu = New-Object System.Windows.Controls.ContextMenu
                $menuitem1 = New-Object System.Windows.Controls.MenuItem
                $submenuitem1 = New-Object System.Windows.Controls.MenuItem
                #Write-Warning ($submenuitem1 | gm | ConvertTo-Json)
                $menuitem1.Header = "Add Item"
                $submenuitem1.Header = "Floor"
                # Store position to be used later
                $submenuitem1.Tag = $Position
                $menuitem1.AddChild($submenuitem1)
                $submenuitem1.Add_Click({
                    #
                    Write-Warning $($this.Tag)
                    Write-Warning "FloorAction click"
                }) | Out-Null
                $menuitem2 = New-Object System.Windows.Controls.MenuItem
                $menuitem2.Header = "FloorAction2"
                $menuitem2.Add_Click({
                    Write-Warning "FloorAction2 click"
                }) | Out-Null
                $contextmenu.Items.Add($menuitem1)
                $contextmenu.Items.Add($menuitem2)
                $MainViewPort.ContextMenu = $contextmenu
                Break
            }
        "User"{
                $contextmenu = New-Object System.Windows.Controls.ContextMenu
                $menuitem1 = New-Object System.Windows.Controls.MenuItem
                $menuitem1.Header = "UserAction"
                $menuitem1.Add_Click({
                    Write-Warning "UserAction click"
                }) | Out-Null
                $menuitem2 = New-Object System.Windows.Controls.MenuItem
                $menuitem2.Header = "UserAction2"
                $menuitem2.Add_Click({
                    Write-Warning "UserAction2 click"
                }) | Out-Null
                $contextmenu.Items.Add($menuitem1)
                $contextmenu.Items.Add($menuitem2)
                $MainViewPort.ContextMenu = $contextmenu
                Break
        }
        "Ball2"{
                $contextmenu = New-Object System.Windows.Controls.ContextMenu
                $menuitem1 = New-Object System.Windows.Controls.MenuItem
                $menuitem1.Header = "Ball2Action"
                $menuitem1.Add_Click({
                    Write-Warning "Ball2Action click"
                }) | Out-Null
                $menuitem2 = New-Object System.Windows.Controls.MenuItem
                $menuitem2.Header = "Ball2Action2"
                $menuitem2.Add_Click({
                    Write-Warning "Ball2Action2 click"
                }) | Out-Null
                $contextmenu.Items.Add($menuitem1)
                $contextmenu.Items.Add($menuitem2)
                $MainViewPort.ContextMenu = $contextmenu
                Break
        }
        "CubeModel"{
                $contextmenu = New-Object System.Windows.Controls.ContextMenu
                $menuitem1 = New-Object System.Windows.Controls.MenuItem
                $menuitem1.Header = "CubeModelAction"
                $menuitem1.Add_Click({
                    Write-Warning "CubeModelAction click"
                }) | Out-Null
                $menuitem2 = New-Object System.Windows.Controls.MenuItem
                $menuitem2.Header = "CubeModelAction2"
                $menuitem2.Add_Click({
                    Write-Warning "CubeModelAction2 click"
                }) | Out-Null
                $contextmenu.Items.Add($menuitem1)
                $contextmenu.Items.Add($menuitem2)
                $MainViewPort.ContextMenu = $contextmenu
                Break
        }
        Default{
        $MainViewPort.ContextMenu = $null
        Break
        }
    }
}
