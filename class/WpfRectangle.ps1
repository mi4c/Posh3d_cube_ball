class WpfRectangle
{
    [System.Windows.Media.Media3D.Point3D]$p0;
    [System.Windows.Media.Media3D.Point3D]$p1;
    [System.Windows.Media.Media3D.Point3D]$p2;
    [System.Windows.Media.Media3D.Point3D]$p3;
    Rectangle([System.Windows.Media.Media3D.Point3D]$P0, [System.Windows.Media.Media3D.Point3D]$P1, [System.Windows.Media.Media3D.Point3D]$P2, [System.Windows.Media.Media3D.Point3D]$P3)
    {
        $this.p0 = $P0;
        $this.p1 = $P1;
        $this.p2 = $P2;
        $this.p3 = $P3;
    }
    Rectangle([System.Windows.Media.Media3D.Point3D]$P0, [Double]$w, [Double]$h, [Double]$d)
    {
        $this.p0 = $P0;
        if ($w -ne 0.0 -and $h -ne 0.0) # front / back
        {
            $this.p1 = [System.Windows.Media.Media3D.Point3D]("$(($p0.X + $w), $p0.Y, $p0.Z)")
            $this.p2 = [System.Windows.Media.Media3D.Point3D]("$(($p0.X + $w), ($p0.Y - $h), $p0.Z)")
            $this.p3 = [System.Windows.Media.Media3D.Point3D]("$($p0.X,      ($p0.Y - $h), $p0.Z)")
        }
        elseif ($w -ne 0.0 -and $d -ne 0.0) # top / bottom
        {
            $this.p1 = [System.Windows.Media.Media3D.Point3D]("$($p0.X,      $p0.Y, ($p0.Z + $d))");
            $this.p2 = [System.Windows.Media.Media3D.Point3D]("$(($p0.X + $w), $p0.Y, ($p0.Z + $d))");
            $this.p3 = [System.Windows.Media.Media3D.Point3D]("$(($p0.X + $w), $p0.Y, $p0.Z)");
        }
        elseif ($h -ne 0.0 -and $d -ne 0.0) # side / side
        {
            $this.p1 = [System.Windows.Media.Media3D.Point3D]("$($p0.X, $p0.Y, ($p0.Z + $d))");
            $this.p2 = [System.Windows.Media.Media3D.Point3D]("$($p0.X, ($p0.Y - $h), ($p0.Z + $d))");
            $this.p3 = [System.Windows.Media.Media3D.Point3D]("$($p0.X, ($p0.Y - $h), $p0.Z)");
        }
    }
    [void]addToMesh([System.Windows.Media.Media3D.MeshGeometry3D]$mesh)
    {
        [WpfTriangle]::addTriangleToMesh($this.p0, $this.p1, $this.p2, $mesh);
        [WpfTriangle]::addTriangleToMesh($this.p2, $this.p3, $this.p0, $mesh);
    }
    [void]addRectangleToMesh([System.Windows.Media.Media3D.Point3D]$p0, [System.Windows.Media.Media3D.Point3D]$p1, [System.Windows.Media.Media3D.Point3D]$p2, [System.Windows.Media.Media3D.Point3D]$p3,[System.Windows.Media.Media3D.MeshGeometry3D]$mesh)
    {
        [WpfTriangle]::addTriangleToMesh($p0, $p1, $p2, $mesh);
        [WpfTriangle]::addTriangleToMesh($p2, $p3, $p0, $mesh);
    }
    static [System.Windows.Media.Media3D.GeometryModel3D]CreateRectangleModel([System.Windows.Media.Media3D.Point3D]$p0, [System.Windows.Media.Media3D.Point3D]$p1, [System.Windows.Media.Media3D.Point3D]$p2, [System.Windows.Media.Media3D.Point3D]$p3)
    {
        return [WpfTriangle]::CreateRectangleModel($p0, $p1, $p2, $p3, $false);
    }
    static [System.Windows.Media.Media3D.GeometryModel3D]CreateRectangleModel([System.Windows.Media.Media3D.Point3D]$p0, [System.Windows.Media.Media3D.Point3D]$p1, [System.Windows.Media.Media3D.Point3D]$p2, [System.Windows.Media.Media3D.Point3D]$p3, [bool]$texture)
    {
        [System.Windows.Media.Media3D.MeshGeometry3D]$mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D
        [WpfTriangle]::addRectangleToMesh($p0, $p1, $p2, $p3, $mesh);
        [System.Windows.Media.Media3D.Material]$material = New-Object System.Windows.Media.Media3D.DiffuseMaterial -Property(@{Brush = 'White'})
        [System.Windows.Media.Media3D.GeometryModel3D]$model = New-Object System.Windows.Media.Media3D.GeometryModel3D -ArgumentList $mesh, $material
        return $model;
    }
}
