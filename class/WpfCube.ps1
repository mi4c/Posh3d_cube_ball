class WpfCube
{
    [System.Windows.Media.Media3D.Point3D]$origin
    [Double]$width
    [Double]$height
    [Double]$depth
    [System.Windows.Media.Media3D.Point3D]centerBottom(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y + $this.height),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    [System.Windows.Media.Media3D.Point3D]center(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y - ($this.height / 2)),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    [System.Windows.Media.Media3D.Point3D]centerTop(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    WpfCube([System.Windows.Media.Media3D.Point3D]$P0,[Double]$w,[Double]$h,[Double]$d){
        $this.width = $w
        $this.height = $h
        $this.depth = $d
        $this.origin = $P0
    }
    WpfCube([WpfCube]$cube){
        $this.width = $cube.width
        $this.height = $cube.height
        $this.depth = $cube.depth
        $this.origin = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList ($cube.origin.X, $cube.origin.Y, $cube.origin.Z)
    }
#    [WpfRectangle]Front($origin,$width,$height)
    [WpfRectangle]Front()
    {
        $r = [WpfRectangle]::New()
        $r.Rectangle("$($this.origin)", $this.width, $this.height, 0);
        return $r;
    }
#    [WpfRectangle]Back($origin,$width,$height,$depth)
    [WpfRectangle]Back()
    {
        $r = [WpfRectangle]::New()
        $r.Rectangle("$(($this.origin.X + $this.width), $this.origin.Y, ($this.origin.Z + $this.depth))", -($this.width), ($this.height), 0)
        return $r;
    }
#    [WpfRectangle]Left($origin, $height, $depth)
    [WpfRectangle]Left()
    {
        $r = [WpfRectangle]::New()
        $r.Rectangle("$($this.origin.X, $this.origin.Y, ($this.origin.Z + $this.depth))", 0, $this.height, -($this.depth))
        return $r;
    }
#    [WpfRectangle]Right($origin, $width, $height, $depth)
    [WpfRectangle]Right()
    {
        $r = [WpfRectangle]::New()
        $r.Rectangle("$(($this.origin.X + $this.width), $this.origin.Y, $this.origin.Z)", 0, $this.height, $this.depth);
        return $r;
    }
#    [WpfRectangle]Top($origin, $width, $depth)
    [WpfRectangle]Top()
    {
        $r = [WpfRectangle]::New()
        $r.Rectangle("$($this.origin)", $this.width, 0, $this.depth);
        return $r;
    }

#    [WpfRectangle]Bottom($origin, $width, $height, $depth)
    [WpfRectangle]Bottom()
    {
        $r = [WpfRectangle]::New()
        $r.Rectangle("$(($this.origin.X + $this.width), ($this.origin.Y - $this.height), $this.origin.Z)", -($this.width), 0, $this.depth);
        return $r;
    }
    static [void]addCubeToMesh([System.Windows.Media.Media3D.Point3D]$p0, [double]$w, [double]$h, [double]$d, [System.Windows.Media.Media3D.MeshGeometry3D]$mesh)
    {
        [WpfCube]$cube = [WpfCube]::new($p0, $w, $h, $d);
        [double]$maxDimension = [Math]::Max($d, [Math]::Max($w, $h));
#        [WpfRectangle]$front =  $cube.Front($p0,$w,$h);
#        [WpfRectangle]$back = $cube.Back($p0,$w,$h,$d);
#        [WpfRectangle]$right = $cube.Right($p0, $h, $d);
#        [WpfRectangle]$left = $cube.Left($p0, $h, $d);
#        [WpfRectangle]$top = $cube.Top($p0,$w,$h);
#        [WpfRectangle]$bottom = $cube.Bottom($p0,$w,$h,$d);
        [WpfRectangle]$front =  $cube.Front();
        [WpfRectangle]$back = $cube.Back();
        [WpfRectangle]$right = $cube.Right();
        [WpfRectangle]$left = $cube.Left();
        [WpfRectangle]$top = $cube.Top();
        [WpfRectangle]$bottom = $cube.Bottom();
        $front.addToMesh($mesh);
        $back.addToMesh($mesh);
        $right.addToMesh($mesh);
        $left.addToMesh($mesh);
        $top.addToMesh($mesh);
        $bottom.addToMesh($mesh);
    }
    [System.Windows.Media.Media3D.GeometryModel3D]CreateModel([System.Drawing.Color]$color)
    {
        return [WPFCube]::CreateCubeModel($this.origin, $this.width, $this.height, $this.depth, $color);
    }
    static [System.Windows.Media.Media3D.GeometryModel3D]CreateCubeModel([System.Windows.Media.Media3D.Point3D]$p0, [double]$w, [double]$h, [double]$d, [System.Drawing.Color]$color)
    {
        $mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D
        [WPFCube]::addCubeToMesh($p0, $w, $h, $d, $mesh);
        $material = New-Object System.Windows.Media.Media3D.DiffuseMaterial -Property (@{Brush = $color.Name});
        $model = New-Object System.Windows.Media.Media3D.GeometryModel3D -ArgumentList $mesh, $material
        return $model;
    }
}
