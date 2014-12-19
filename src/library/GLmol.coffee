#
# GLmol - Molecular Viewer on WebGL/Javascript (0.47)
#  (C) Copyright 2011-2012, biochem_fan
#      License: dual license of MIT or LGPL3
#
#  Contributors:
#    Robert Hanson for parseXYZ, deferred instantiation
#
#  This program uses
#      Three.js 
#         https://github.com/mrdoob/three.js
#         Copyright (c) 2010-2012 three.js Authors. All rights reserved.
#      jQuery
#         http://jquery.org/
#         Copyright (c) 2011 John Resig
# 

# Workaround for Intel GMA series (gl_FrontFacing causes compilation error)
THREE.ShaderLib.lambert.fragmentShader = THREE.ShaderLib.lambert.fragmentShader.replace("gl_FrontFacing", "true")
THREE.ShaderLib.lambert.vertexShader = THREE.ShaderLib.lambert.vertexShader.replace(/\}$/, "#ifdef DOUBLE_SIDED\n if (transformedNormal.z < 0.0) vLightFront = vLightBack;\n #endif\n }")
TV3 = THREE.Vector3
TF3 = THREE.Face3
TCo = THREE.Color
THREE.Geometry::colorAll = (color) ->
  i = 0

  while i < @faces.length
    @faces[i].color = color
    i++
  return

THREE.Matrix4::isIdentity = ->
  i = 0

  while i < 4
    j = 0

    while j < 4
      return false  if (if @elements[i * 4 + j] isnt (i is j) then 1 else 0)
      j++
    i++
  true

GLmol = (id, suppressAutoload) ->
  @create id, suppressAutoload  if id
  true
GLmol::create = (id, suppressAutoload) ->
  @Nucleotides = [
    "  G"
    "  A"
    "  T"
    "  C"
    "  U"
    " DG"
    " DA"
    " DT"
    " DC"
    " DU"
  ]
  @ElementColors =
    H: 0xcccccc
    C: 0xaaaaaa
    O: 0xcc0000
    N: 0x0000cc
    S: 0xcccc00
    P: 0x6622cc
    F: 0x00cc00
    CL: 0x00cc00
    BR: 0x882200
    I: 0x6600aa
    FE: 0xcc6600
    CA: 0x8888aa

  
  # Reference: A. Bondi, J. Phys. Chem., 1964, 68, 441.
  @vdwRadii =
    H: 1.2
    Li: 1.82
    Na: 2.27
    K: 2.75
    C: 1.7
    N: 1.55
    O: 1.52
    F: 1.47
    P: 1.80
    S: 1.80
    CL: 1.75
    BR: 1.85
    SE: 1.90
    ZN: 1.39
    CU: 1.4
    NI: 1.63

  @id = id
  @aaScale = 1 # or 2
  @container = $("#" + @id)
  @WIDTH = @container.width() * @aaScale
  @HEIGHT = @container.height() * @aaScale

  @ASPECT = @WIDTH / @HEIGHT
  @NEAR = 1
  FAR = 800

  @CAMERA_Z = -150
  @renderer = new THREE.WebGLRenderer(antialias: true)
  @renderer.sortObjects = false # hopefully improve performance
  # 'antialias: true' now works in Firefox too!
  # setting this.aaScale = 2 will enable antialias in older Firefox but GPU load increases.
  @renderer.domElement.style.width = "100%"
  @renderer.domElement.style.height = "100%"
  @container.append @renderer.domElement
  @renderer.setSize @WIDTH, @HEIGHT
  @camera = new THREE.PerspectiveCamera(20, @ASPECT, 1, 800) # will be updated anyway
  @camera.position = new TV3(0, 0, @CAMERA_Z)
  @camera.lookAt new TV3(0, 0, 0)
  @perspectiveCamera = @camera
  @orthoscopicCamera = new THREE.OrthographicCamera()
  @orthoscopicCamera.position.z = @CAMERA_Z
  @orthoscopicCamera.lookAt new TV3(0, 0, 0)
  self = this
  $(window).resize -> # only window can capture resize event
    self.WIDTH = self.container.width() * self.aaScale
    self.HEIGHT = self.container.height() * self.aaScale
    self.ASPECT = self.WIDTH / self.HEIGHT
    self.renderer.setSize self.WIDTH, self.HEIGHT
    self.camera.aspect = self.ASPECT
    self.camera.updateProjectionMatrix()
    self.show()
    return

  @scene = null
  @rotationGroup = null # which contains modelGroup
  @modelGroup = null
  @bgColor = 0x000000
  @fov = 20
  @fogStart = 0.4
  @slabNear = -50 # relative to the center of rotationGroup
  @slabFar = +50
  
  # Default values
  @sphereRadius = 1.5
  @cylinderRadius = 0.4
  @lineWidth = 1.5 * @aaScale
  @curveWidth = 3 * @aaScale
  @defaultColor = 0xcccccc
  @sphereQuality = 16 #16;
  @cylinderQuality = 16 #8;
  @axisDIV = 5 # 3 still gives acceptable quality
  @strandDIV = 6
  @nucleicAcidStrandDIV = 4
  @tubeDIV = 8
  @coilWidth = 0.3
  @helixSheetWidth = 1.3
  @nucleicAcidWidth = 0.8
  @thickness = 0.4
  
  # UI variables
  @cq = new THREE.Quaternion(1, 0, 0, 0)
  @dq = new THREE.Quaternion(1, 0, 0, 0)
  @isDragging = false
  @mouseStartX = 0
  @mouseStartY = 0
  @currentModelPos = 0
  @cz = 0
  @enableMouse()
  return  if suppressAutoload
  @loadMolecule()
  return

GLmol::setupLights = (scene) ->
  directionalLight = new THREE.DirectionalLight(0xffffff)
  directionalLight.position = new TV3(0.2, 0.2, -1).normalize()
  directionalLight.intensity = 1.2
  scene.add directionalLight
  ambientLight = new THREE.AmbientLight(0x202020)
  scene.add ambientLight
  return

GLmol::parseSDF = (str) ->
  atoms = @atoms
  protein = @protein
  lines = str.split("\n")
  return  if lines.length < 4
  atomCount = parseInt(lines[3].substr(0, 3))
  return  if isNaN(atomCount) or atomCount <= 0
  bondCount = parseInt(lines[3].substr(3, 3))
  offset = 4
  return  if lines.length < 4 + atomCount + bondCount
  i = 1

  while i <= atomCount
    line = lines[offset]
    offset++
    atom = {}
    atom.serial = i
    atom.x = parseFloat(line.substr(0, 10))
    atom.y = parseFloat(line.substr(10, 10))
    atom.z = parseFloat(line.substr(20, 10))
    atom.hetflag = true
    atom.atom = atom.elem = line.substr(31, 3).replace(RegExp(" ", "g"), "")
    atom.bonds = []
    atom.bondOrder = []
    atoms[i] = atom
    i++
  i = 1
  while i <= bondCount
    line = lines[offset]
    offset++
    from = parseInt(line.substr(0, 3))
    to = parseInt(line.substr(3, 3))
    order = parseInt(line.substr(6, 3))
    atoms[from].bonds.push to
    atoms[from].bondOrder.push order
    atoms[to].bonds.push from
    atoms[to].bondOrder.push order
    i++
  protein.smallMolecule = true
  true

GLmol::parseXYZ = (str) ->
  atoms = @atoms
  protein = @protein
  lines = str.split("\n")
  return  if lines.length < 3
  atomCount = parseInt(lines[0].substr(0, 3))
  return  if isNaN(atomCount) or atomCount <= 0
  return  if lines.length < atomCount + 2
  offset = 2
  i = 1

  while i <= atomCount
    line = lines[offset++]
    tokens = line.replace(/^\s+/, "").replace(/\s+/g, " ").split(" ")
    console.log tokens
    atom = {}
    atom.serial = i
    atom.atom = atom.elem = tokens[0]
    atom.x = parseFloat(tokens[1])
    atom.y = parseFloat(tokens[2])
    atom.z = parseFloat(tokens[3])
    atom.hetflag = true
    atom.bonds = []
    atom.bondOrder = []
    atoms[i] = atom
    i++
  i = 1 # hopefully XYZ is small enough

  while i < atomCount
    j = i + 1

    while j <= atomCount
      if @isConnected(atoms[i], atoms[j])
        atoms[i].bonds.push j
        atoms[i].bondOrder.push 1
        atoms[j].bonds.push i
        atoms[j].bondOrder.push 1
      j++
    i++
  protein.smallMolecule = true
  true

GLmol::parsePDB2 = (str) ->
  atoms = @atoms
  protein = @protein
  molID = undefined
  atoms_cnt = 0
  lines = str.split("\n")
  i = 0

  while i < lines.length
    line = lines[i].replace(/^\s*/, "") # remove indent
    recordName = line.substr(0, 6)
    if recordName is "ATOM  " or recordName is "HETATM"
      atom = undefined
      resn = undefined
      chain = undefined
      resi = undefined
      x = undefined
      y = undefined
      z = undefined
      hetflag = undefined
      elem = undefined
      serial = undefined
      altLoc = undefined
      b = undefined
      altLoc = line.substr(16, 1)
      if altLoc isnt " " and altLoc isnt "A" # FIXME: ad hoc
        i++
        continue
      serial = parseInt(line.substr(6, 5))
      atom = line.substr(12, 4).replace(RegExp(" ", "g"), "")
      resn = line.substr(17, 3)
      chain = line.substr(21, 1)
      resi = parseInt(line.substr(22, 5))
      x = parseFloat(line.substr(30, 8))
      y = parseFloat(line.substr(38, 8))
      z = parseFloat(line.substr(46, 8))
      b = parseFloat(line.substr(60, 8))
      elem = line.substr(76, 2).replace(RegExp(" ", "g"), "")
      # for some incorrect PDB files
      elem = line.substr(12, 4).replace(RegExp(" ", "g"), "")  if elem is ""
      if line[0] is "H"
        hetflag = true
      else
        hetflag = false
      atoms[serial] =
        resn: resn
        x: x
        y: y
        z: z
        elem: elem
        hetflag: hetflag
        chain: chain
        resi: resi
        serial: serial
        atom: atom
        bonds: []
        ss: "c"
        color: 0xffffff
        bonds: []
        bondOrder: []
        b: b #', altLoc': altLoc
    else if recordName is "SHEET "
      startChain = line.substr(21, 1)
      startResi = parseInt(line.substr(22, 4))
      endChain = line.substr(32, 1)
      endResi = parseInt(line.substr(33, 4))
      protein.sheet.push [
        startChain
        startResi
        endChain
        endResi
      ]
    else if recordName is "CONECT"
      
      # MEMO: We don't have to parse SSBOND, LINK because both are also 
      # described in CONECT. But what about 2JYT???
      from = parseInt(line.substr(6, 5))
      j = 0

      while j < 4
        to = parseInt(line.substr([
          11
          16
          21
          26
        ][j], 5))
        if isNaN(to)
          j++
          continue
        if atoms[from]?
          atoms[from].bonds.push to
          atoms[from].bondOrder.push 1
        j++
    else if recordName is "HELIX "
      startChain = line.substr(19, 1)
      startResi = parseInt(line.substr(21, 4))
      endChain = line.substr(31, 1)
      endResi = parseInt(line.substr(33, 4))
      protein.helix.push [
        startChain
        startResi
        endChain
        endResi
      ]
    else if recordName is "CRYST1"
      protein.a = parseFloat(line.substr(6, 9))
      protein.b = parseFloat(line.substr(15, 9))
      protein.c = parseFloat(line.substr(24, 9))
      protein.alpha = parseFloat(line.substr(33, 7))
      protein.beta = parseFloat(line.substr(40, 7))
      protein.gamma = parseFloat(line.substr(47, 7))
      protein.spacegroup = line.substr(55, 11)
      @defineCell()
    else if recordName is "REMARK"
      type = parseInt(line.substr(7, 3))
      if type is 290 and line.substr(13, 5) is "SMTRY"
        n = parseInt(line[18]) - 1
        m = parseInt(line.substr(21, 2))
        protein.symMat[m] = new THREE.Matrix4().identity()  unless protein.symMat[m]?
        protein.symMat[m].elements[n] = parseFloat(line.substr(24, 9))
        protein.symMat[m].elements[n + 4] = parseFloat(line.substr(34, 9))
        protein.symMat[m].elements[n + 8] = parseFloat(line.substr(44, 9))
        protein.symMat[m].elements[n + 12] = parseFloat(line.substr(54, 10))
      else if type is 350 and line.substr(13, 5) is "BIOMT"
        n = parseInt(line[18]) - 1
        m = parseInt(line.substr(21, 2))
        protein.biomtMatrices[m] = new THREE.Matrix4().identity()  unless protein.biomtMatrices[m]?
        protein.biomtMatrices[m].elements[n] = parseFloat(line.substr(24, 9))
        protein.biomtMatrices[m].elements[n + 4] = parseFloat(line.substr(34, 9))
        protein.biomtMatrices[m].elements[n + 8] = parseFloat(line.substr(44, 9))
        protein.biomtMatrices[m].elements[n + 12] = parseFloat(line.substr(54, 10))
      else if type is 350 and line.substr(11, 11) is "BIOMOLECULE"
        protein.biomtMatrices = []
        protein.biomtChains = ""
      else protein.biomtChains += line.substr(41, 40)  if type is 350 and line.substr(34, 6) is "CHAINS"
    else if recordName is "HEADER"
      protein.pdbID = line.substr(62, 4)
    else if recordName is "TITLE "
      protein.title = ""  unless protein.title?
      protein.title += line.substr(10, 70) + "\n" # CHECK: why 60 is not enough???
    else "pass"  if recordName is "COMPND"
    i++
  
  # TODO: Implement me!
  
  # Assign secondary structures 
  i = 0
  while i < atoms.length
    atom = atoms[i]
    unless atom?
      i++
      continue
    found = false
    
    # MEMO: Can start chain and end chain differ?
    j = 0
    while j < protein.sheet.length
      unless atom.chain is protein.sheet[j][0]
        j++
        continue
      if atom.resi < protein.sheet[j][1]
        j++
        continue
      if atom.resi > protein.sheet[j][3]
        j++
        continue
      atom.ss = "s"
      atom.ssbegin = true  if atom.resi is protein.sheet[j][1]
      atom.ssend = true  if atom.resi is protein.sheet[j][3]
      j++
    j = 0
    while j < protein.helix.length
      unless atom.chain is protein.helix[j][0]
        j++
        continue
      if atom.resi < protein.helix[j][1]
        j++
        continue
      if atom.resi > protein.helix[j][3]
        j++
        continue
      atom.ss = "h"
      if atom.resi is protein.helix[j][1]
        atom.ssbegin = true
      else atom.ssend = true  if atom.resi is protein.helix[j][3]
      j++
    i++
  protein.smallMolecule = false
  true


# Catmull-Rom subdivision
GLmol::subdivide = (_points, DIV) -> # points as Vector3
  ret = []
  points = _points
  points = new Array() # Smoothing test
  points.push _points[0]
  i = 1
  lim = _points.length - 1

  while i < lim
    p1 = _points[i]
    p2 = _points[i + 1]
    if p1.smoothen
      points.push new TV3((p1.x + p2.x) / 2, (p1.y + p2.y) / 2, (p1.z + p2.z) / 2)
    else
      points.push p1
    i++
  points.push _points[_points.length - 1]
  i = -1
  size = points.length

  while i <= size - 3
    p0 = points[(if (i is -1) then 0 else i)]
    p1 = points[i + 1]
    p2 = points[i + 2]
    p3 = points[(if (i is size - 3) then size - 1 else i + 3)]
    v0 = new TV3().sub(p2, p0).multiplyScalar(0.5)
    v1 = new TV3().sub(p3, p1).multiplyScalar(0.5)
    j = 0

    while j < DIV
      t = 1.0 / DIV * j
      x = p1.x + t * v0.x + t * t * (-3 * p1.x + 3 * p2.x - 2 * v0.x - v1.x) + t * t * t * (2 * p1.x - 2 * p2.x + v0.x + v1.x)
      y = p1.y + t * v0.y + t * t * (-3 * p1.y + 3 * p2.y - 2 * v0.y - v1.y) + t * t * t * (2 * p1.y - 2 * p2.y + v0.y + v1.y)
      z = p1.z + t * v0.z + t * t * (-3 * p1.z + 3 * p2.z - 2 * v0.z - v1.z) + t * t * t * (2 * p1.z - 2 * p2.z + v0.z + v1.z)
      ret.push new TV3(x, y, z)
      j++
    i++
  ret.push points[points.length - 1]
  ret

GLmol::drawAtomsAsSphere = (group, atomlist, defaultRadius, forceDefault, scale) ->
  sphereGeometry = new THREE.SphereGeometry(1, @sphereQuality, @sphereQuality) # r, seg, ring
  i = 0

  while i < atomlist.length
    atom = @atoms[atomlist[i]]
    unless atom?
      i++
      continue
    sphereMaterial = new THREE.MeshLambertMaterial(color: atom.color)
    sphere = new THREE.Mesh(sphereGeometry, sphereMaterial)
    group.add sphere
    r = (if (not forceDefault and @vdwRadii[atom.elem]?) then @vdwRadii[atom.elem] else defaultRadius)
    r *= scale  if not forceDefault and scale
    sphere.scale.x = sphere.scale.y = sphere.scale.z = r
    sphere.position.x = atom.x
    sphere.position.y = atom.y
    sphere.position.z = atom.z
    i++
  return


# about two times faster than sphere when div = 2
GLmol::drawAtomsAsIcosahedron = (group, atomlist, defaultRadius, forceDefault) ->
  geo = @IcosahedronGeometry()
  i = 0

  while i < atomlist.length
    atom = @atoms[atomlist[i]]
    unless atom?
      i++
      continue
    mat = new THREE.MeshLambertMaterial(color: atom.color)
    sphere = new THREE.Mesh(geo, mat)
    sphere.scale.x = sphere.scale.y = sphere.scale.z = (if (not forceDefault and @vdwRadii[atom.elem]?) then @vdwRadii[atom.elem] else defaultRadius)
    group.add sphere
    sphere.position.x = atom.x
    sphere.position.y = atom.y
    sphere.position.z = atom.z
    i++
  return

GLmol::isConnected = (atom1, atom2) ->
  s = atom1.bonds.indexOf(atom2.serial)
  return atom1.bondOrder[s]  unless s is -1
  return 0  if @protein.smallMolecule and (atom1.hetflag or atom2.hetflag) # CHECK: or should I ?
  distSquared = (atom1.x - atom2.x) * (atom1.x - atom2.x) + (atom1.y - atom2.y) * (atom1.y - atom2.y) + (atom1.z - atom2.z) * (atom1.z - atom2.z)
  
  #   if (atom1.altLoc != atom2.altLoc) return false;
  return 0  if isNaN(distSquared)
  return 0  if distSquared < 0.5 # maybe duplicate position.
  return 0  if distSquared > 1.3 and (atom1.elem is "H" or atom2.elem is "H" or atom1.elem is "D" or atom2.elem is "D")
  return 1  if distSquared < 3.42 and (atom1.elem is "S" or atom2.elem is "S")
  return 0  if distSquared > 2.78
  1

GLmol::drawBondAsStickSub = (group, atom1, atom2, bondR, order) ->
  delta = undefined
  tmp = undefined
  delta = @calcBondDelta(atom1, atom2, bondR * 2.3)  if order > 1
  p1 = new TV3(atom1.x, atom1.y, atom1.z)
  p2 = new TV3(atom2.x, atom2.y, atom2.z)
  mp = p1.clone().addSelf(p2).multiplyScalar(0.5)
  c1 = new TCo(atom1.color)
  c2 = new TCo(atom2.color)
  if order is 1 or order is 3
    @drawCylinder group, p1, mp, bondR, atom1.color
    @drawCylinder group, p2, mp, bondR, atom2.color
  if order > 1
    tmp = mp.clone().addSelf(delta)
    @drawCylinder group, p1.clone().addSelf(delta), tmp, bondR, atom1.color
    @drawCylinder group, p2.clone().addSelf(delta), tmp, bondR, atom2.color
    tmp = mp.clone().subSelf(delta)
    @drawCylinder group, p1.clone().subSelf(delta), tmp, bondR, atom1.color
    @drawCylinder group, p2.clone().subSelf(delta), tmp, bondR, atom2.color
  return

GLmol::drawBondsAsStick = (group, atomlist, bondR, atomR, ignoreNonbonded, multipleBonds, scale) ->
  sphereGeometry = new THREE.SphereGeometry(1, @sphereQuality, @sphereQuality)
  nAtoms = atomlist.length
  mp = undefined
  forSpheres = []
  bondR /= 2.5  unless not multipleBonds
  _i = 0

  while _i < nAtoms
    i = atomlist[_i]
    atom1 = @atoms[i]
    unless atom1?
      _i++
      continue
    _j = _i + 1

    while _j < _i + 30 and _j < nAtoms
      j = atomlist[_j]
      atom2 = @atoms[j]
      unless atom2?
        _j++
        continue
      order = @isConnected(atom1, atom2)
      if order is 0
        _j++
        continue
      atom1.connected = atom2.connected = true
      @drawBondAsStickSub group, atom1, atom2, bondR, (if (!!multipleBonds) then order else 1)
      _j++
    _j = 0

    while _j < atom1.bonds.length
      j = atom1.bonds[_j]
      if j < i + 30 # be conservative!
        _j++
        continue
      if atomlist.indexOf(j) is -1
        _j++
        continue
      atom2 = @atoms[j]
      unless atom2?
        _j++
        continue
      atom1.connected = atom2.connected = true
      @drawBondAsStickSub group, atom1, atom2, bondR, (if (!!multipleBonds) then atom1.bondOrder[_j] else 1)
      _j++
    forSpheres.push i  if atom1.connected
    _i++
  @drawAtomsAsSphere group, forSpheres, atomR, not scale, scale
  return

GLmol::defineCell = ->
  p = @protein
  return  unless p.a?
  p.ax = p.a
  p.ay = 0
  p.az = 0
  p.bx = p.b * Math.cos(Math.PI / 180.0 * p.gamma)
  p.by = p.b * Math.sin(Math.PI / 180.0 * p.gamma)
  p.bz = 0
  p.cx = p.c * Math.cos(Math.PI / 180.0 * p.beta)
  p.cy = p.c * (Math.cos(Math.PI / 180.0 * p.alpha) - Math.cos(Math.PI / 180.0 * p.gamma) * Math.cos(Math.PI / 180.0 * p.beta) / Math.sin(Math.PI / 180.0 * p.gamma))
  p.cz = Math.sqrt(p.c * p.c * Math.sin(Math.PI / 180.0 * p.beta) * Math.sin(Math.PI / 180.0 * p.beta) - p.cy * p.cy)
  return

GLmol::drawUnitcell = (group) ->
  p = @protein
  return  unless p.a?
  vertices = [
    [
      0
      0
      0
    ]
    [
      p.ax
      p.ay
      p.az
    ]
    [
      p.bx
      p.by
      p.bz
    ]
    [
      p.ax + p.bx
      p.ay + p.by
      p.az + p.bz
    ]
    [
      p.cx
      p.cy
      p.cz
    ]
    [
      p.cx + p.ax
      p.cy + p.ay
      p.cz + p.az
    ]
    [
      p.cx + p.bx
      p.cy + p.by
      p.cz + p.bz
    ]
    [
      p.cx + p.ax + p.bx
      p.cy + p.ay + p.by
      p.cz + p.az + p.bz
    ]
  ]
  edges = [
    0
    1
    0
    2
    1
    3
    2
    3
    4
    5
    4
    6
    5
    7
    6
    7
    0
    4
    1
    5
    2
    6
    3
    7
  ]
  geo = new THREE.Geometry()
  i = 0

  while i < edges.length
    geo.vertices.push new TV3(vertices[edges[i]][0], vertices[edges[i]][1], vertices[edges[i]][2])
    i++
  lineMaterial = new THREE.LineBasicMaterial(
    linewidth: 1
    color: 0xcccccc
  )
  line = new THREE.Line(geo, lineMaterial)
  line.type = THREE.LinePieces
  group.add line
  return


# TODO: Find inner side of a ring
GLmol::calcBondDelta = (atom1, atom2, sep) ->
  dot = undefined
  axis = new TV3(atom1.x - atom2.x, atom1.y - atom2.y, atom1.z - atom2.z).normalize()
  found = null
  i = 0

  while i < atom1.bonds.length and not found
    atom = @atoms[atom1.bonds[i]]
    unless atom
      i++
      continue
    found = atom  if atom.serial isnt atom2.serial and atom.elem isnt "H"
    i++
  i = 0

  while i < atom2.bonds.length and not found
    atom = @atoms[atom2.bonds[i]]
    unless atom
      i++
      continue
    found = atom  if atom.serial isnt atom1.serial and atom.elem isnt "H"
    i++
  if found
    tmp = new TV3(atom1.x - found.x, atom1.y - found.y, atom1.z - found.z).normalize()
    dot = tmp.dot(axis)
    delta = new TV3(tmp.x - axis.x * dot, tmp.y - axis.y * dot, tmp.z - axis.z * dot)
  if not found or Math.abs(dot - 1) < 0.001 or Math.abs(dot + 1) < 0.001
    if axis.x < 0.01 and axis.y < 0.01
      delta = new TV3(0, -axis.z, axis.y)
    else
      delta = new TV3(-axis.y, axis.x, 0)
  delta.normalize().multiplyScalar sep
  delta

GLmol::drawBondsAsLineSub = (geo, atom1, atom2, order) ->
  delta = undefined
  tmp = undefined
  vs = geo.vertices
  cs = geo.colors
  delta = @calcBondDelta(atom1, atom2, 0.15)  if order > 1
  p1 = new TV3(atom1.x, atom1.y, atom1.z)
  p2 = new TV3(atom2.x, atom2.y, atom2.z)
  mp = p1.clone().addSelf(p2).multiplyScalar(0.5)
  c1 = new TCo(atom1.color)
  c2 = new TCo(atom2.color)
  if order is 1 or order is 3
    vs.push p1
    cs.push c1
    vs.push mp
    cs.push c1
    vs.push p2
    cs.push c2
    vs.push mp
    cs.push c2
  if order > 1
    vs.push p1.clone().addSelf(delta)
    cs.push c1
    vs.push tmp = mp.clone().addSelf(delta)
    cs.push c1
    vs.push p2.clone().addSelf(delta)
    cs.push c2
    vs.push tmp
    cs.push c2
    vs.push p1.clone().subSelf(delta)
    cs.push c1
    vs.push tmp = mp.clone().subSelf(delta)
    cs.push c1
    vs.push p2.clone().subSelf(delta)
    cs.push c2
    vs.push tmp
    cs.push c2
  return

GLmol::drawBondsAsLine = (group, atomlist, lineWidth) ->
  geo = new THREE.Geometry()
  nAtoms = atomlist.length
  _i = 0

  while _i < nAtoms
    i = atomlist[_i]
    atom1 = @atoms[i]
    unless atom1?
      _i++
      continue
    _j = _i + 1

    while _j < _i + 30 and _j < nAtoms
      j = atomlist[_j]
      atom2 = @atoms[j]
      unless atom2?
        _j++
        continue
      order = @isConnected(atom1, atom2)
      if order is 0
        _j++
        continue
      @drawBondsAsLineSub geo, atom1, atom2, order
      _j++
    _j = 0

    while _j < atom1.bonds.length
      j = atom1.bonds[_j]
      if j < i + 30 # be conservative!
        _j++
        continue
      if atomlist.indexOf(j) is -1
        _j++
        continue
      atom2 = @atoms[j]
      unless atom2?
        _j++
        continue
      @drawBondsAsLineSub geo, atom1, atom2, atom1.bondOrder[_j]
      _j++
    _i++
  lineMaterial = new THREE.LineBasicMaterial(linewidth: lineWidth)
  lineMaterial.vertexColors = true
  line = new THREE.Line(geo, lineMaterial)
  line.type = THREE.LinePieces
  group.add line
  return

GLmol::drawSmoothCurve = (group, _points, width, colors, div) ->
  return  if _points.length is 0
  div = (if (not (div?)) then 5 else div)
  geo = new THREE.Geometry()
  points = @subdivide(_points, div)
  i = 0

  while i < points.length
    geo.vertices.push points[i]
    geo.colors.push new TCo(colors[(if (i is 0) then 0 else Math.round((i - 1) / div))])
    i++
  lineMaterial = new THREE.LineBasicMaterial(linewidth: width)
  lineMaterial.vertexColors = true
  line = new THREE.Line(geo, lineMaterial)
  line.type = THREE.LineStrip
  group.add line
  return

GLmol::drawAsCross = (group, atomlist, delta) ->
  geo = new THREE.Geometry()
  points = [
    [
      delta
      0
      0
    ]
    [
      -delta
      0
      0
    ]
    [
      0
      delta
      0
    ]
    [
      0
      -delta
      0
    ]
    [
      0
      0
      delta
    ]
    [
      0
      0
      -delta
    ]
  ]
  i = 0
  lim = atomlist.length

  while i < lim
    atom = @atoms[atomlist[i]]
    unless atom?
      i++
      continue
    c = new TCo(atom.color)
    j = 0

    while j < 6
      geo.vertices.push new TV3(atom.x + points[j][0], atom.y + points[j][1], atom.z + points[j][2])
      geo.colors.push c
      j++
    i++
  lineMaterial = new THREE.LineBasicMaterial(linewidth: @lineWidth)
  lineMaterial.vertexColors = true
  line = new THREE.Line(geo, lineMaterial, THREE.LinePieces)
  group.add line
  return


# FIXME: Winkled...
GLmol::drawSmoothTube = (group, _points, colors, radii) ->
  return  if _points.length < 2
  circleDiv = @tubeDIV
  axisDiv = @axisDIV
  geo = new THREE.Geometry()
  points = @subdivide(_points, axisDiv)
  prevAxis1 = new TV3()
  prevAxis2 = undefined
  i = 0
  lim = points.length

  while i < lim
    r = undefined
    idx = (i - 1) / axisDiv
    if i is 0
      r = radii[0]
    else
      if idx % 1 is 0
        r = radii[idx]
      else
        floored = Math.floor(idx)
        tmp = idx - floored
        r = radii[floored] * tmp + radii[floored + 1] * (1 - tmp)
    delta = undefined
    axis1 = undefined
    axis2 = undefined
    if i < lim - 1
      delta = new TV3().sub(points[i], points[i + 1])
      axis1 = new TV3(0, -delta.z, delta.y).normalize().multiplyScalar(r)
      axis2 = new TV3().cross(delta, axis1).normalize().multiplyScalar(r)
      
      #      var dir = 1, offset = 0;
      if prevAxis1.dot(axis1) < 0
        axis1.negate()
        axis2.negate() #dir = -1;//offset = 2 * Math.PI / axisDiv;
      prevAxis1 = axis1
      prevAxis2 = axis2
    else
      axis1 = prevAxis1
      axis2 = prevAxis2
    j = 0

    while j < circleDiv
      angle = 2 * Math.PI / circleDiv * j #* dir  + offset;
      c = Math.cos(angle)
      s = Math.sin(angle)
      geo.vertices.push new TV3(points[i].x + c * axis1.x + s * axis2.x, points[i].y + c * axis1.y + s * axis2.y, points[i].z + c * axis1.z + s * axis2.z)
      j++
    i++
  offset = 0
  i = 0
  lim = points.length - 1

  while i < lim
    c = new TCo(colors[Math.round((i - 1) / axisDiv)])
    reg = 0
    r1 = new TV3().sub(geo.vertices[offset], geo.vertices[offset + circleDiv]).lengthSq()
    r2 = new TV3().sub(geo.vertices[offset], geo.vertices[offset + circleDiv + 1]).lengthSq()
    if r1 > r2
      r1 = r2
      reg = 1
    j = 0

    while j < circleDiv
      geo.faces.push new TF3(offset + j, offset + (j + reg) % circleDiv + circleDiv, offset + (j + 1) % circleDiv)
      geo.faces.push new TF3(offset + (j + 1) % circleDiv, offset + (j + reg) % circleDiv + circleDiv, offset + (j + reg + 1) % circleDiv + circleDiv)
      geo.faces[geo.faces.length - 2].color = c
      geo.faces[geo.faces.length - 1].color = c
      j++
    offset += circleDiv
    i++
  geo.computeFaceNormals()
  geo.computeVertexNormals false
  mat = new THREE.MeshLambertMaterial()
  mat.vertexColors = THREE.FaceColors
  mesh = new THREE.Mesh(geo, mat)
  mesh.doubleSided = true
  group.add mesh
  return

GLmol::drawMainchainCurve = (group, atomlist, curveWidth, atomName, div) ->
  points = []
  colors = []
  currentChain = undefined
  currentResi = undefined
  div = 5  unless div?
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    if (atom.atom is atomName) and not atom.hetflag
      if currentChain isnt atom.chain or currentResi + 1 isnt atom.resi
        @drawSmoothCurve group, points, curveWidth, colors, div
        points = []
        colors = []
      points.push new TV3(atom.x, atom.y, atom.z)
      colors.push atom.color
      currentChain = atom.chain
      currentResi = atom.resi
  @drawSmoothCurve group, points, curveWidth, colors, div
  return

GLmol::drawMainchainTube = (group, atomlist, atomName, radius) ->
  points = []
  colors = []
  radii = []
  currentChain = undefined
  currentResi = undefined
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    if (atom.atom is atomName) and not atom.hetflag
      if currentChain isnt atom.chain or currentResi + 1 isnt atom.resi
        @drawSmoothTube group, points, colors, radii
        points = []
        colors = []
        radii = []
      points.push new TV3(atom.x, atom.y, atom.z)
      unless radius?
        radii.push (if (atom.b > 0) then atom.b / 100 else 0.3)
      else
        radii.push radius
      colors.push atom.color
      currentChain = atom.chain
      currentResi = atom.resi
  @drawSmoothTube group, points, colors, radii
  return

GLmol::drawStrip = (group, p1, p2, colors, div, thickness) ->
  return  if (p1.length) < 2
  div = div or @axisDIV
  p1 = @subdivide(p1, div)
  p2 = @subdivide(p2, div)
  return @drawThinStrip(group, p1, p2, colors, div)  unless thickness
  geo = new THREE.Geometry()
  vs = geo.vertices
  fs = geo.faces
  axis = undefined
  p1v = undefined
  p2v = undefined
  a1v = undefined
  a2v = undefined
  i = 0
  lim = p1.length

  while i < lim
    vs.push p1v = p1[i] # 0
    vs.push p1v # 1
    vs.push p2v = p2[i] # 2
    vs.push p2v # 3
    if i < lim - 1
      toNext = p1[i + 1].clone().subSelf(p1[i])
      toSide = p2[i].clone().subSelf(p1[i])
      axis = toSide.crossSelf(toNext).normalize().multiplyScalar(thickness)
    vs.push a1v = p1[i].clone().addSelf(axis) # 4
    vs.push a1v # 5
    vs.push a2v = p2[i].clone().addSelf(axis) # 6
    vs.push a2v # 7
    i++
  faces = [
    [
      0
      2
      -6
      -8
    ]
    [
      -4
      -2
      6
      4
    ]
    [
      7
      3
      -5
      -1
    ]
    [
      -3
      -7
      1
      5
    ]
  ]
  i = 1
  lim = p1.length

  while i < lim
    offset = 8 * i
    color = new TCo(colors[Math.round((i - 1) / div)])
    j = 0

    while j < 4
      f = new THREE.Face4(offset + faces[j][0], offset + faces[j][1], offset + faces[j][2], offset + faces[j][3], `undefined`, color)
      fs.push f
      j++
    i++
  vsize = vs.length - 8 # Cap
  i = 0

  while i < 4
    vs.push vs[i * 2]
    vs.push vs[vsize + i * 2]
    i++
  vsize += 8
  fs.push new THREE.Face4(vsize, vsize + 2, vsize + 6, vsize + 4, `undefined`, fs[0].color)
  fs.push new THREE.Face4(vsize + 1, vsize + 5, vsize + 7, vsize + 3, `undefined`, fs[fs.length - 3].color)
  geo.computeFaceNormals()
  geo.computeVertexNormals false
  material = new THREE.MeshLambertMaterial()
  material.vertexColors = THREE.FaceColors
  mesh = new THREE.Mesh(geo, material)
  mesh.doubleSided = true
  group.add mesh
  return

GLmol::drawThinStrip = (group, p1, p2, colors, div) ->
  geo = new THREE.Geometry()
  i = 0
  lim = p1.length

  while i < lim
    geo.vertices.push p1[i] # 2i
    geo.vertices.push p2[i] # 2i + 1
    i++
  i = 1
  lim = p1.length

  while i < lim
    f = new THREE.Face4(2 * i, 2 * i + 1, 2 * i - 1, 2 * i - 2)
    f.color = new TCo(colors[Math.round((i - 1) / div)])
    geo.faces.push f
    i++
  geo.computeFaceNormals()
  geo.computeVertexNormals false
  material = new THREE.MeshLambertMaterial()
  material.vertexColors = THREE.FaceColors
  mesh = new THREE.Mesh(geo, material)
  mesh.doubleSided = true
  group.add mesh
  return

GLmol::IcosahedronGeometry = ->
  @icosahedron = new THREE.IcosahedronGeometry(1)  unless @icosahedron
  @icosahedron

GLmol::drawCylinder = (group, from, to, radius, color, cap) ->
  return  if not from or not to
  midpoint = new TV3().add(from, to).multiplyScalar(0.5)
  color = new TCo(color)
  unless @cylinderGeometry
    @cylinderGeometry = new THREE.CylinderGeometry(1, 1, 1, @cylinderQuality, 1, not cap)
    @cylinderGeometry.faceUvs = []
    @faceVertexUvs = []
  cylinderMaterial = new THREE.MeshLambertMaterial(color: color.getHex())
  cylinder = new THREE.Mesh(@cylinderGeometry, cylinderMaterial)
  cylinder.position = midpoint
  cylinder.lookAt from
  cylinder.updateMatrix()
  cylinder.matrixAutoUpdate = false
  m = new THREE.Matrix4().makeScale(radius, radius, from.distanceTo(to))
  m.rotateX Math.PI / 2
  cylinder.matrix.multiplySelf m
  group.add cylinder
  return


# FIXME: transition!
GLmol::drawHelixAsCylinder = (group, atomlist, radius) ->
  start = null
  currentChain = undefined
  currentResi = undefined
  others = []
  beta = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  if not atom? or atom.hetflag
    others.push atom.serial  if (atom.ss isnt "h" and atom.ss isnt "s") or atom.ssend or atom.ssbegin
    beta.push atom.serial  if atom.ss is "s"
    continue  unless atom.atom is "CA"
    if atom.ss is "h" and atom.ssend
      @drawCylinder group, new TV3(start.x, start.y, start.z), new TV3(atom.x, atom.y, atom.z), radius, atom.color, true  if start?
      start = null
    currentChain = atom.chain
    currentResi = atom.resi
    start = atom  if not start? and atom.ss is "h" and atom.ssbegin
  @drawCylinder group, new TV3(start.x, start.y, start.z), new TV3(atom.x, atom.y, atom.z), radius, atom.color  if start?
  @drawMainchainTube group, others, "CA", 0.3
  @drawStrand group, beta, `undefined`, `undefined`, true, 0, @helixSheetWidth, false, @thickness * 2
  return

GLmol::drawCartoon = (group, atomlist, doNotSmoothen, thickness) ->
  @drawStrand group, atomlist, 2, `undefined`, true, `undefined`, `undefined`, doNotSmoothen, thickness
  return

GLmol::drawStrand = (group, atomlist, num, div, fill, coilWidth, helixSheetWidth, doNotSmoothen, thickness) ->
  num = num or @strandDIV
  div = div or @axisDIV
  coilWidth = coilWidth or @coilWidth
  (if doNotSmoothen is (not (doNotSmoothen?)) then false else doNotSmoothen)
  helixSheetWidth = helixSheetWidth or @helixSheetWidth
  points = []
  k = 0

  while k < num
    points[k] = []
    k++
  colors = []
  currentChain = undefined
  currentResi = undefined
  currentCA = undefined
  prevCO = null
  ss = null
  ssborder = false
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    if (atom.atom is "O" or atom.atom is "CA") and not atom.hetflag
      if atom.atom is "CA"
        if currentChain isnt atom.chain or currentResi + 1 isnt atom.resi
          j = 0

          while not thickness and j < num
            @drawSmoothCurve group, points[j], 1, colors, div
            j++
          @drawStrip group, points[0], points[num - 1], colors, div, thickness  if fill
          points = []
          k = 0

          while k < num
            points[k] = []
            k++
          colors = []
          prevCO = null
          ss = null
          ssborder = false
        currentCA = new TV3(atom.x, atom.y, atom.z)
        currentChain = atom.chain
        currentResi = atom.resi
        ss = atom.ss
        ssborder = atom.ssstart or atom.ssend
        colors.push atom.color
      else # O
        O = new TV3(atom.x, atom.y, atom.z)
        O.subSelf currentCA
        O.normalize() # can be omitted for performance
        O.multiplyScalar (if (ss is "c") then coilWidth else helixSheetWidth)
        O.negate()  if prevCO? and O.dot(prevCO) < 0
        prevCO = O
        j = 0

        while j < num
          delta = -1 + 2 / (num - 1) * j
          v = new TV3(currentCA.x + prevCO.x * delta, currentCA.y + prevCO.y * delta, currentCA.z + prevCO.z * delta)
          v.smoothen = true  if not doNotSmoothen and ss is "s"
          points[j].push v
          j++
  j = 0

  while not thickness and j < num
    @drawSmoothCurve group, points[j], 1, colors, div
    j++
  @drawStrip group, points[0], points[num - 1], colors, div, thickness  if fill
  return

GLmol::drawNucleicAcidLadderSub = (geo, lineGeo, atoms, color) ->
  
  #        color.r *= 0.9; color.g *= 0.9; color.b *= 0.9;
  if atoms[0]? and atoms[1]? and atoms[2]? and atoms[3]? and atoms[4]? and atoms[5]?
    baseFaceId = geo.vertices.length
    i = 0

    while i <= 5
      geo.vertices.push atoms[i]
      i++
    geo.faces.push new TF3(baseFaceId, baseFaceId + 1, baseFaceId + 2)
    geo.faces.push new TF3(baseFaceId, baseFaceId + 2, baseFaceId + 3)
    geo.faces.push new TF3(baseFaceId, baseFaceId + 3, baseFaceId + 4)
    geo.faces.push new TF3(baseFaceId, baseFaceId + 4, baseFaceId + 5)
    j = geo.faces.length - 4
    lim = geo.faces.length

    while j < lim
      geo.faces[j].color = color
      j++
  if atoms[4]? and atoms[3]? and atoms[6]? and atoms[7]? and atoms[8]?
    baseFaceId = geo.vertices.length
    geo.vertices.push atoms[4]
    geo.vertices.push atoms[3]
    geo.vertices.push atoms[6]
    geo.vertices.push atoms[7]
    geo.vertices.push atoms[8]
    i = 0

    while i <= 4
      geo.colors.push color
      i++
    geo.faces.push new TF3(baseFaceId, baseFaceId + 1, baseFaceId + 2)
    geo.faces.push new TF3(baseFaceId, baseFaceId + 2, baseFaceId + 3)
    geo.faces.push new TF3(baseFaceId, baseFaceId + 3, baseFaceId + 4)
    j = geo.faces.length - 3
    lim = geo.faces.length

    while j < lim
      geo.faces[j].color = color
      j++
  return

GLmol::drawNucleicAcidLadder = (group, atomlist) ->
  geo = new THREE.Geometry()
  lineGeo = new THREE.Geometry()
  baseAtoms = [
    "N1"
    "C2"
    "N3"
    "C4"
    "C5"
    "C6"
    "N9"
    "C8"
    "N7"
  ]
  currentChain = undefined
  currentResi = undefined
  currentComponent = new Array(baseAtoms.length)
  color = new TCo(0xcc0000)
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  if not atom? or atom.hetflag
    if atom.resi isnt currentResi or atom.chain isnt currentChain
      @drawNucleicAcidLadderSub geo, lineGeo, currentComponent, color
      currentComponent = new Array(baseAtoms.length)
    pos = baseAtoms.indexOf(atom.atom)
    currentComponent[pos] = new TV3(atom.x, atom.y, atom.z)  unless pos is -1
    color = new TCo(atom.color)  if atom.atom is "O3'"
    currentResi = atom.resi
    currentChain = atom.chain
  @drawNucleicAcidLadderSub geo, lineGeo, currentComponent, color
  geo.computeFaceNormals()
  mat = new THREE.MeshLambertMaterial()
  mat.vertexColors = THREE.VertexColors
  mesh = new THREE.Mesh(geo, mat)
  mesh.doubleSided = true
  group.add mesh
  return

GLmol::drawNucleicAcidStick = (group, atomlist) ->
  currentChain = undefined
  currentResi = undefined
  start = null
  end = null
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  if not atom? or atom.hetflag
    if atom.resi isnt currentResi or atom.chain isnt currentChain
      @drawCylinder group, new TV3(start.x, start.y, start.z), new TV3(end.x, end.y, end.z), 0.3, start.color, true  if start? and end?
      start = null
      end = null
    start = atom  if atom.atom is "O3'"
    if atom.resn is "  A" or atom.resn is "  G" or atom.resn is " DA" or atom.resn is " DG"
      end = atom  if atom.atom is "N1" #  N1(AG), N3(CTU)
    else end = atom  if atom.atom is "N3"
    currentResi = atom.resi
    currentChain = atom.chain
  @drawCylinder group, new TV3(start.x, start.y, start.z), new TV3(end.x, end.y, end.z), 0.3, start.color, true  if start? and end?
  return

GLmol::drawNucleicAcidLine = (group, atomlist) ->
  currentChain = undefined
  currentResi = undefined
  start = null
  end = null
  geo = new THREE.Geometry()
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  if not atom? or atom.hetflag
    if atom.resi isnt currentResi or atom.chain isnt currentChain
      if start? and end?
        geo.vertices.push new TV3(start.x, start.y, start.z)
        geo.colors.push new TCo(start.color)
        geo.vertices.push new TV3(end.x, end.y, end.z)
        geo.colors.push new TCo(start.color)
      start = null
      end = null
    start = atom  if atom.atom is "O3'"
    if atom.resn is "  A" or atom.resn is "  G" or atom.resn is " DA" or atom.resn is " DG"
      end = atom  if atom.atom is "N1" #  N1(AG), N3(CTU)
    else end = atom  if atom.atom is "N3"
    currentResi = atom.resi
    currentChain = atom.chain
  if start? and end?
    geo.vertices.push new TV3(start.x, start.y, start.z)
    geo.colors.push new TCo(start.color)
    geo.vertices.push new TV3(end.x, end.y, end.z)
    geo.colors.push new TCo(start.color)
  mat = new THREE.LineBasicMaterial(
    linewidth: 1
    linejoin: false
  )
  mat.linewidth = 1.5
  mat.vertexColors = true
  line = new THREE.Line(geo, mat, THREE.LinePieces)
  group.add line
  return

GLmol::drawCartoonNucleicAcid = (group, atomlist, div, thickness) ->
  @drawStrandNucleicAcid group, atomlist, 2, div, true, `undefined`, thickness
  return

GLmol::drawStrandNucleicAcid = (group, atomlist, num, div, fill, nucleicAcidWidth, thickness) ->
  nucleicAcidWidth = nucleicAcidWidth or @nucleicAcidWidth
  div = div or @axisDIV
  num = num or @nucleicAcidStrandDIV
  points = []
  k = 0

  while k < num
    points[k] = []
    k++
  colors = []
  currentChain = undefined
  currentResi = undefined
  currentO3 = undefined
  prevOO = null
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    if (atom.atom is "O3'" or atom.atom is "OP2") and not atom.hetflag
      if atom.atom is "O3'" # to connect 3' end. FIXME: better way to do?
        if currentChain isnt atom.chain or currentResi + 1 isnt atom.resi
          if currentO3
            j = 0

            while j < num
              delta = -1 + 2 / (num - 1) * j
              points[j].push new TV3(currentO3.x + prevOO.x * delta, currentO3.y + prevOO.y * delta, currentO3.z + prevOO.z * delta)
              j++
          @drawStrip group, points[0], points[1], colors, div, thickness  if fill
          j = 0

          while not thickness and j < num
            @drawSmoothCurve group, points[j], 1, colors, div
            j++
          points = []
          k = 0

          while k < num
            points[k] = []
            k++
          colors = []
          prevOO = null
        currentO3 = new TV3(atom.x, atom.y, atom.z)
        currentChain = atom.chain
        currentResi = atom.resi
        colors.push atom.color
      else # OP2
        unless currentO3
          prevOO = null
          continue
        # for 5' phosphate (e.g. 3QX3)
        O = new TV3(atom.x, atom.y, atom.z)
        O.subSelf currentO3
        O.normalize().multiplyScalar nucleicAcidWidth # TODO: refactor
        O.negate()  if prevOO? and O.dot(prevOO) < 0
        prevOO = O
        j = 0

        while j < num
          delta = -1 + 2 / (num - 1) * j
          points[j].push new TV3(currentO3.x + prevOO.x * delta, currentO3.y + prevOO.y * delta, currentO3.z + prevOO.z * delta)
          j++
        currentO3 = null
  if currentO3
    j = 0

    while j < num
      delta = -1 + 2 / (num - 1) * j
      points[j].push new TV3(currentO3.x + prevOO.x * delta, currentO3.y + prevOO.y * delta, currentO3.z + prevOO.z * delta)
      j++
  @drawStrip group, points[0], points[1], colors, div, thickness  if fill
  j = 0

  while not thickness and j < num
    @drawSmoothCurve group, points[j], 1, colors, div
    j++
  return

GLmol::drawDottedLines = (group, points, color) ->
  geo = new THREE.Geometry()
  step = 0.3
  i = 0
  lim = Math.floor(points.length / 2)

  while i < lim
    p1 = points[2 * i]
    p2 = points[2 * i + 1]
    delta = p2.clone().subSelf(p1)
    dist = delta.length()
    delta.normalize().multiplyScalar step
    jlim = Math.floor(dist / step)
    j = 0

    while j < jlim
      p = new TV3(p1.x + delta.x * j, p1.y + delta.y * j, p1.z + delta.z * j)
      geo.vertices.push p
      j++
    geo.vertices.push p2  if jlim % 2 is 1
    i++
  mat = new THREE.LineBasicMaterial(color: color.getHex())
  mat.linewidth = 2
  line = new THREE.Line(geo, mat, THREE.LinePieces)
  group.add line
  return

GLmol::getAllAtoms = ->
  ret = []
  for i of @atoms
    ret.push @atoms[i].serial
  ret


# Probably I can refactor using higher-order functions.
GLmol::getHetatms = (atomlist) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    ret.push atom.serial  if atom.hetflag
  ret

GLmol::removeSolvents = (atomlist) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    ret.push atom.serial  unless atom.resn is "HOH"
  ret

GLmol::getProteins = (atomlist) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    ret.push atom.serial  unless atom.hetflag
  ret


# TODO: Test
GLmol::excludeAtoms = (atomlist, deleteList) ->
  ret = []
  blackList = new Object()
  for _i of deleteList
    blackList[deleteList[_i]] = true
  for _i of atomlist
    i = atomlist[_i]
    ret.push i  unless blackList[i]
  ret

GLmol::getSidechains = (atomlist) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    continue  if atom.hetflag
    continue  if atom.atom is "C" or atom.atom is "O" or (atom.atom is "N" and atom.resn isnt "PRO")
    ret.push atom.serial
  ret

GLmol::getAtomsWithin = (atomlist, extent) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    continue  if atom.x < extent[0][0] or atom.x > extent[1][0]
    continue  if atom.y < extent[0][1] or atom.y > extent[1][1]
    continue  if atom.z < extent[0][2] or atom.z > extent[1][2]
    ret.push atom.serial
  ret

GLmol::getExtent = (atomlist) ->
  xmin = ymin = zmin = 9999
  xmax = ymax = zmax = -9999
  xsum = ysum = zsum = cnt = 0
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    cnt++
    xsum += atom.x
    ysum += atom.y
    zsum += atom.z
    xmin = (if (xmin < atom.x) then xmin else atom.x)
    ymin = (if (ymin < atom.y) then ymin else atom.y)
    zmin = (if (zmin < atom.z) then zmin else atom.z)
    xmax = (if (xmax > atom.x) then xmax else atom.x)
    ymax = (if (ymax > atom.y) then ymax else atom.y)
    zmax = (if (zmax > atom.z) then zmax else atom.z)
  [
    [
      xmin
      ymin
      zmin
    ]
    [
      xmax
      ymax
      zmax
    ]
    [
      xsum / cnt
      ysum / cnt
      zsum / cnt
    ]
  ]

GLmol::getResiduesById = (atomlist, resi) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    ret.push atom.serial  unless resi.indexOf(atom.resi) is -1
  ret

GLmol::getResidueBySS = (atomlist, ss) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    ret.push atom.serial  unless ss.indexOf(atom.ss) is -1
  ret

GLmol::getChain = (atomlist, chain) ->
  ret = []
  chains = {}
  chain = chain.toString() # concat if Array
  i = 0
  lim = chain.length

  while i < lim
    chains[chain.substr(i, 1)] = true
    i++
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    ret.push atom.serial  if chains[atom.chain]
  ret


# for HETATM only
GLmol::getNonbonded = (atomlist, chain) ->
  ret = []
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    ret.push atom.serial  if atom.hetflag and atom.bonds.length is 0
  ret

GLmol::colorByAtom = (atomlist, colors) ->
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    c = colors[atom.elem]
    c = @ElementColors[atom.elem]  unless c?
    c = @defaultColor  unless c?
    atom.color = c
  return


# MEMO: Color only CA. maybe I should add atom.cartoonColor.
GLmol::colorByStructure = (atomlist, helixColor, sheetColor, colorSidechains) ->
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    continue  if not colorSidechains and (atom.atom isnt "CA" or atom.hetflag)
    if atom.ss[0] is "s"
      atom.color = sheetColor
    else atom.color = helixColor  if atom.ss[0] is "h"
  return

GLmol::colorByBFactor = (atomlist, colorSidechains) ->
  minB = 1000
  maxB = -1000
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    continue  if atom.hetflag
    if colorSidechains or atom.atom is "CA" or atom.atom is "O3'"
      minB = atom.b  if minB > atom.b
      maxB = atom.b  if maxB < atom.b
  mid = (maxB + minB) / 2
  range = (maxB - minB) / 2
  return  if range < 0.01 and range > -0.01
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    continue  if atom.hetflag
    if colorSidechains or atom.atom is "CA" or atom.atom is "O3'"
      color = new TCo(0)
      if atom.b < mid
        color.setHSV 0.667, (mid - atom.b) / range, 1
      else
        color.setHSV 0, (atom.b - mid) / range, 1
      atom.color = color.getHex()
  return

GLmol::colorByChain = (atomlist, colorSidechains) ->
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    continue  if atom.hetflag
    if colorSidechains or atom.atom is "CA" or atom.atom is "O3'"
      color = new TCo(0)
      color.setHSV (atom.chain.charCodeAt(0) * 5) % 17 / 17.0, 1, 0.9
      atom.color = color.getHex()
  return

GLmol::colorByResidue = (atomlist, residueColors) ->
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    c = residueColors[atom.resn]
    atom.color = c  if c?
  return

GLmol::colorAtoms = (atomlist, c) ->
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    atom.color = c
  return

GLmol::colorByPolarity = (atomlist, polar, nonpolar) ->
  polarResidues = [
    "ARG"
    "HIS"
    "LYS"
    "ASP"
    "GLU"
    "SER"
    "THR"
    "ASN"
    "GLN"
    "CYS"
  ]
  nonPolarResidues = [
    "GLY"
    "PRO"
    "ALA"
    "VAL"
    "LEU"
    "ILE"
    "MET"
    "PHE"
    "TYR"
    "TRP"
  ]
  colorMap = {}
  for i of polarResidues
    colorMap[polarResidues[i]] = polar
  for i of nonPolarResidues
    colorMap[nonPolarResidues[i]] = nonpolar
  @colorByResidue atomlist, colorMap
  return


# TODO: Add near(atomlist, neighbor, distanceCutoff)
# TODO: Add expandToResidue(atomlist)
GLmol::colorChainbow = (atomlist, colorSidechains) ->
  cnt = 0
  atom = undefined
  i = undefined
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    cnt++  if (colorSidechains or atom.atom isnt "CA" or atom.atom isnt "O3'") and not atom.hetflag
  total = cnt
  cnt = 0
  for i of atomlist
    atom = @atoms[atomlist[i]]
    continue  unless atom?
    if (colorSidechains or atom.atom isnt "CA" or atom.atom isnt "O3'") and not atom.hetflag
      color = new TCo(0)
      color.setHSV 240.0 / 360 * (1 - cnt / total), 1, 0.9
      atom.color = color.getHex()
      cnt++
  return

GLmol::drawSymmetryMates2 = (group, asu, matrices) ->
  return  unless matrices?
  asu.matrixAutoUpdate = false
  cnt = 1
  @protein.appliedMatrix = new THREE.Matrix4()
  i = 0

  while i < matrices.length
    mat = matrices[i]
    if not mat? or mat.isIdentity()
      i++
      continue
    console.log mat
    symmetryMate = THREE.SceneUtils.cloneObject(asu)
    symmetryMate.matrix = mat
    group.add symmetryMate
    j = 0

    while j < 16
      @protein.appliedMatrix.elements[j] += mat.elements[j]
      j++
    cnt++
    i++
  @protein.appliedMatrix.multiplyScalar cnt
  return

GLmol::drawSymmetryMatesWithTranslation2 = (group, asu, matrices) ->
  return  unless matrices?
  p = @protein
  asu.matrixAutoUpdate = false
  i = 0

  while i < matrices.length
    mat = matrices[i]
    unless mat?
      i++
      continue
    a = -1

    while a <= 0
      b = -1

      while b <= 0
        c = -1

        while c <= 0
          translationMat = new THREE.Matrix4().makeTranslation(p.ax * a + p.bx * b + p.cx * c, p.ay * a + p.by * b + p.cy * c, p.az * a + p.bz * b + p.cz * c)
          symop = mat.clone().multiplySelf(translationMat)
          if symop.isIdentity()
            c++
            continue
          symmetryMate = THREE.SceneUtils.cloneObject(asu)
          symmetryMate.matrix = symop
          group.add symmetryMate
          c++
        b++
      a++
    i++
  return

GLmol::defineRepresentation = ->
  all = @getAllAtoms()
  hetatm = @removeSolvents(@getHetatms(all))
  @colorByAtom all, {}
  @colorByChain all
  @drawAtomsAsSphere @modelGroup, hetatm, @sphereRadius
  @drawMainchainCurve @modelGroup, all, @curveWidth, "P"
  @drawCartoon @modelGroup, all, @curveWidth
  return

GLmol::getView = ->
  unless @modelGroup
    return [
      0
      0
      0
      0
      0
      0
      0
      1
    ]
  pos = @modelGroup.position
  q = @rotationGroup.quaternion
  [
    pos.x
    pos.y
    pos.z
    @rotationGroup.position.z
    q.x
    q.y
    q.z
    q.w
  ]

GLmol::setView = (arg) ->
  return  if not @modelGroup or not @rotationGroup
  @modelGroup.position.x = arg[0]
  @modelGroup.position.y = arg[1]
  @modelGroup.position.z = arg[2]
  @rotationGroup.position.z = arg[3]
  @rotationGroup.quaternion.x = arg[4]
  @rotationGroup.quaternion.y = arg[5]
  @rotationGroup.quaternion.z = arg[6]
  @rotationGroup.quaternion.w = arg[7]
  @show()
  return

GLmol::setBackground = (hex, a) ->
  a = a | 1.0
  @bgColor = hex
  @renderer.setClearColorHex hex, a
  @scene.fog.color = new TCo(hex)
  return

GLmol::initializeScene = ->
  
  # CHECK: Should I explicitly call scene.deallocateObject?
  @scene = new THREE.Scene()
  @scene.fog = new THREE.Fog(@bgColor, 100, 200)
  @modelGroup = new THREE.Object3D()
  @rotationGroup = new THREE.Object3D()
  @rotationGroup.useQuaternion = true
  @rotationGroup.quaternion = new THREE.Quaternion(1, 0, 0, 0)
  @rotationGroup.add @modelGroup
  @scene.add @rotationGroup
  @setupLights @scene
  return

GLmol::zoomInto = (atomlist, keepSlab) ->
  tmp = @getExtent(atomlist)
  center = new TV3(tmp[2][0], tmp[2][1], tmp[2][2]) #(tmp[0][0] + tmp[1][0]) / 2, (tmp[0][1] + tmp[1][1]) / 2, (tmp[0][2] + tmp[1][2]) / 2);
  center = @protein.appliedMatrix.multiplyVector3(center)  if @protein.appliedMatrix
  @modelGroup.position = center.multiplyScalar(-1)
  x = tmp[1][0] - tmp[0][0]
  y = tmp[1][1] - tmp[0][1]
  z = tmp[1][2] - tmp[0][2]
  maxD = Math.sqrt(x * x + y * y + z * z)
  maxD = 25  if maxD < 25
  unless keepSlab
    @slabNear = -maxD / 1.9
    @slabFar = maxD / 3
  @rotationGroup.position.z = maxD * 0.35 / Math.tan(Math.PI / 180.0 * @camera.fov / 2) - 150
  @rotationGroup.quaternion = new THREE.Quaternion(1, 0, 0, 0)
  return

GLmol::rebuildScene = ->
  time = new Date()
  view = @getView()
  @initializeScene()
  @defineRepresentation()
  @setView view
  console.log "builded scene in " + (+new Date() - time) + "ms"
  return

GLmol::loadMolecule = (repressZoom) ->
  @loadMoleculeStr repressZoom, $("#" + @id + "_src").val()
  return

GLmol::loadMoleculeStr = (repressZoom, source) ->
  time = new Date()
  @protein =
    sheet: []
    helix: []
    biomtChains: ""
    biomtMatrices: []
    symMat: []
    pdbID: ""
    title: ""

  @atoms = []
  @parsePDB2 source
  @parseXYZ source  unless @parseSDF(source)
  console.log "parsed in " + (+new Date() - time) + "ms"
  title = $("#" + @id + "_pdbTitle")
  titleStr = ""
  titleStr += "<a href=\"http://www.rcsb.org/pdb/explore/explore.do?structureId=" + @protein.pdbID + "\">" + @protein.pdbID + "</a>"  unless @protein.pdbID is ""
  titleStr += "<br>" + @protein.title  unless @protein.title is ""
  title.html titleStr
  @rebuildScene true
  @zoomInto @getAllAtoms()  if not repressZoom? or not repressZoom
  @show()
  return

GLmol::setSlabAndFog = ->
  center = @rotationGroup.position.z - @camera.position.z
  center = 1  if center < 1
  @camera.near = center + @slabNear
  @camera.near = 1  if @camera.near < 1
  @camera.far = center + @slabFar
  @camera.far = @camera.near + 1  if @camera.near + 1 > @camera.far
  if @camera instanceof THREE.PerspectiveCamera
    @camera.fov = @fov
  else
    @camera.right = center * Math.tan(Math.PI / 180 * @fov)
    @camera.left = -@camera.right
    @camera.top = @camera.right / @ASPECT
    @camera.bottom = -@camera.top
  @camera.updateProjectionMatrix()
  @scene.fog.near = @camera.near + @fogStart * (@camera.far - @camera.near)
  
  #   if (this.scene.fog.near > center) this.scene.fog.near = center;
  @scene.fog.far = @camera.far
  return

GLmol::enableMouse = ->
  me = this
  glDOM = $(@renderer.domElement)
  
  # TODO: Better touch panel support. 
  # Contribution is needed as I don't own any iOS or Android device with WebGL support.
  glDOM.bind "mousedown touchstart", (ev) ->
    ev.preventDefault()
    return  unless me.scene
    x = ev.pageX
    y = ev.pageY
    if ev.originalEvent.targetTouches and ev.originalEvent.targetTouches[0]
      x = ev.originalEvent.targetTouches[0].pageX
      y = ev.originalEvent.targetTouches[0].pageY
    return  unless x?
    me.isDragging = true
    me.mouseButton = ev.which
    me.mouseStartX = x
    me.mouseStartY = y
    me.cq = me.rotationGroup.quaternion
    me.cz = me.rotationGroup.position.z
    me.currentModelPos = me.modelGroup.position.clone()
    me.cslabNear = me.slabNear
    me.cslabFar = me.slabFar
    return

  glDOM.bind "DOMMouseScroll mousewheel", (ev) -> # Zoom
    ev.preventDefault()
    return  unless me.scene
    scaleFactor = (me.rotationGroup.position.z - me.CAMERA_Z) * 0.85
    if ev.originalEvent.detail # Webkit
      me.rotationGroup.position.z += scaleFactor * ev.originalEvent.detail / 10
    # Firefox
    else me.rotationGroup.position.z -= scaleFactor * ev.originalEvent.wheelDelta / 400  if ev.originalEvent.wheelDelta
    console.log ev.originalEvent.wheelDelta, ev.originalEvent.detail, me.rotationGroup.position.z
    me.show()
    return

  glDOM.bind "contextmenu", (ev) ->
    ev.preventDefault()
    return

  $("body").bind "mouseup touchend", (ev) ->
    me.isDragging = false
    return

  glDOM.bind "mousemove touchmove", (ev) -> # touchmove
    ev.preventDefault()
    return  unless me.scene
    return  unless me.isDragging
    mode = 0
    modeRadio = $("input[name=" + me.id + "_mouseMode]:checked")
    mode = parseInt(modeRadio.val())  if modeRadio.length > 0
    x = ev.pageX
    y = ev.pageY
    if ev.originalEvent.targetTouches and ev.originalEvent.targetTouches[0]
      x = ev.originalEvent.targetTouches[0].pageX
      y = ev.originalEvent.targetTouches[0].pageY
    return  unless x?
    dx = (x - me.mouseStartX) / me.WIDTH
    dy = (y - me.mouseStartY) / me.HEIGHT
    r = Math.sqrt(dx * dx + dy * dy)
    if mode is 3 or (me.mouseButton is 3 and ev.ctrlKey) # Slab
      me.slabNear = me.cslabNear + dx * 100
      me.slabFar = me.cslabFar + dy * 100
    else if mode is 2 or me.mouseButton is 3 or ev.shiftKey # Zoom
      scaleFactor = (me.rotationGroup.position.z - me.CAMERA_Z) * 0.85
      scaleFactor = 80  if scaleFactor < 80
      me.rotationGroup.position.z = me.cz - dy * scaleFactor
    else if mode is 1 or me.mouseButton is 2 or ev.ctrlKey # Translate
      scaleFactor = (me.rotationGroup.position.z - me.CAMERA_Z) * 0.85
      scaleFactor = 20  if scaleFactor < 20
      translationByScreen = new TV3(-dx * scaleFactor, -dy * scaleFactor, 0)
      q = me.rotationGroup.quaternion
      qinv = new THREE.Quaternion(q.x, q.y, q.z, q.w).inverse().normalize()
      translation = qinv.multiplyVector3(translationByScreen)
      me.modelGroup.position.x = me.currentModelPos.x + translation.x
      me.modelGroup.position.y = me.currentModelPos.y + translation.y
      me.modelGroup.position.z = me.currentModelPos.z + translation.z
    else if (mode is 0 or me.mouseButton is 1) and r isnt 0 # Rotate
      rs = Math.sin(r * Math.PI) / r
      me.dq.x = Math.cos(r * Math.PI)
      me.dq.y = 0
      me.dq.z = rs * dx
      me.dq.w = rs * dy
      me.rotationGroup.quaternion = new THREE.Quaternion(1, 0, 0, 0)
      me.rotationGroup.quaternion.multiplySelf me.dq
      me.rotationGroup.quaternion.multiplySelf me.cq
    me.show()
    return

  return

GLmol::show = ->
  return  unless @scene
  time = new Date()
  @setSlabAndFog()
  @renderer.render @scene, @camera
  console.log "rendered in " + (+new Date() - time) + "ms"
  return


# For scripting
GLmol::doFunc = (func) ->
  func this
  return


module.exports = GLmol