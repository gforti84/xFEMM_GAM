classdef fpproc < mfemmpproc
% fpproc   class for post-processing of mfemm solutions
%
% fpproc is a class wrapper for the FPProc_interface C++ class, which
% offers access to the FPProc finite element post-processing functions
%
% Syntax
%
% fpproc()
% fpproc(filename)
%
% Description
%
% fpproc() creates a new fpproc class without opening any solution file
% for processing.
%
% fpproc(filename) creates a new fpproc class and attempts to load the
% file in filename for processing.
%
%
% fpproc Methods:
%    opendocument - open a .ans solution document
%    getpointvalues - get all solution outputs at points
%    getb - get flux density values only at points
%    geth - get magnetic field intensity values only at points
%    geta - get magnetic vector potential values only at points
%    smoothon - turn on B and H smoothing over mesh elements
%    smoothoff - turn off B and H smoothing over mesh elements
%    clearcontour - clear a contour
%    addcontour - add one or more points to a contour
%    lineintegral - perform a line integral along a contour
%    selectblock - select a block
%    groupselectblock - select blocks by group number
%    selectallblocks - selects mfemmdeps.every block
%    clearblock - clear all block selections
%    blockintegral - perfom integrals over selected blocks
%    gapintegral - get integral of quantity in air gap boundary region
%    getprobleminfo - get information about the problem
%    getcircuitprops - get properties of a circuit
%    newcontour - create a new contour, discarding old
%    totalfieldenergy - calculates total field energy
%    totalfieldcoenergy - calculates total field coenergy
%    plotBfield - creates a plot of the flux density vector field
%    plotAfield - creates a plot of the magnetic vetor potential
%    nummeshnodes - returns the number of nodes in the mesh
%    numelements - returns the number of elements in the mesh
%    getvertices - gets coordinates of mesh vertices
%    getelements - gets information about mesh elements
%    getcentroids - gets the centroids of mesh elements
%    getareas - gets the areas of mesh elements
%    getvolumes - gets the volumes of mesh elements
%    numgroupelements - gets the number of elements in groups
%    getgroupvertices - gets coordinates of mesh vertices in groups
%    getgroupelements - gets information about mesh elements in groups
%    getgroupcentroids - gets the centroids of mesh elements in groups
%    getgroupareas - gets the areas of mesh elements in groups
%    getgroupvolumes - gets the volumes of mesh elements in groups
%    getgapb - 
%    getgapa - 
%    getgapharmonics - 
%
    
% Copyright 2012-2014 Richard Crozier
% 
%    Licensed under the Apache License, Version 2.0 (the "License");
%    you may not use this file except in compliance with the License.
%    You may obtain a copy of the License at
% 
%        http://www.apache.org/licenses/LICENSE-2.0
% 
%    Unless required by applicable law or agreed to in writing, software
%    distributed under the License is distributed on an "AS IS" BASIS,
%    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%    See the License for the specific language governing permissions and
%    limitations under the License.
    
    
    methods  
        %% Constructor - Create a new C++ class instance
        function this = fpproc(filename)
            
            this.objectHandle = fpproc_interface_mex('new');
            
            if nargin == 1
                this.opendocument(filename);
            end
            
        end

        %% Destructor - Destroy the C++ class instance
        function delete(this)
            fpproc_interface_mex('delete', this.objectHandle);
        end

        %%%%%%      The C++ Class Interface Methods       %%%%%%%

        function result = opendocument(this, filename)
            % loads a femm solution file for processing. Throws an error if
            % the file could not be opened.
            %
            % Syntax
            %
            % result = fpproc.opendocument(filename)
            %
            % Input
            % 
            %  filename - the path to the file to be opened for processing.
            %    If the file is successfully opened the isdocopen property
            %    will be set to true, and the openfilename property set to
            %    the full path to the file
            %
            % Output
            %
            %  result - is true if the file was successfully opened or
            %    false otherwise.
            
            if ~exist(filename, 'file')
                error('File could not be found.');
            end
            
            if ispc
                % escape the slashes, as the string is passed verbatim to
                % fpproc, and the slashes mangle it
                checkedfilename = strrep(filename, '\', '\\');
            else
                checkedfilename = filename;
            end
            
            result = fpproc_interface_mex('opendocument', this.objectHandle, checkedfilename);
            
            if result == 0
                this.isdocopen = false;
                this.openfilename = '';
                error('Document could not be opened')
            else
                this.isdocopen = true;
                this.openfilename = filename;
                % try and load the femmproblem structure from the file
                try
                    this.FemmProblem = loadfemmfile (filename);
                catch
                    warning ('Couldn''t load FemmProblem from solution file.')
                end
                    
            end
            
        end

        function pvals = getpointvalues(this, x, y)
            % getpointvalues(X,Y) Get the values associated with the points
            % at X,Y from the solution
            %
            % Syntax
            %
            % pvals = fpproc.getpointvalues(X, Y)
            %
            % Input
            %
            %   X,Y - X and Y are matrices of the same size containing
            %     sets of x and y coordinates at which the point properties
            %     are to be determined. Internally these will be reshaped
            %     as X(:),Y(:), i.e. two column vectors.
            %
            % Output
            %
            % pvals is a matrix containing the values associated with each
            % point defined by X,Y from the solution. Each column of pvals
            % corresponds to a given x,y point, and the rows of pvals refer
            % to the following values:
            % 
            % A     vector potential A or flux f
            % B1    flux density Bx if planar, Br if axisymmetric
            % B2    flux density By if planar, Bz if axisymmetric
            % Sig   electrical conductivity s
            % E     stored energy density
            % H1    field intensity Hx if planar, Hr if axisymmetric
            % H2    field intensity Hy if planar, Hz if axisymmetric
            % Je    eddy current density
            % Js    source current density
            % Mu1   relative permeability Mu_x if planar, Mu_r if axisymmetric
            % Mu2   relative permeability Mu_y if planar, Mu_z if axisymmetric
            % Pe    Power density dissipated through ohmic losses
            % Ph    Power density dissipated by hysteresis
            % ff    Fill Factor
            %

            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            
            if nargin == 2 && size (x,2) == 2
                y = x(:,2);
                x = x(:,1);
            end
            
            pvals = fpproc_interface_mex('getpointvals', this.objectHandle, x(:), y(:));
            
        end
        
        function B = getb(this, x, y)
            % Get the flux density values associated with the points at X,Y
            % from the solution
            %
            % Syntax
            %
            % B = fpproc.getb(X, Y)
            %
            % Input
            %
            %   X,Y - X and Y are matrices of the same size containing
            %     sets of x and y coordinates at which the point properties
            %     are to be determined. Internally these will be reshaped
            %     as X(:),Y(:), i.e. two column vectors.
            %
            % Output
            %
            %   B - the flux density at the requested coordinates
            %
            %
            
            if (nargin==3)
                
                B = this.getpointvalues(x,y);
                
                B = B(2:3,:);
                
            elseif (nargin==2)
                
                B = this.getpointvalues(x);
                
                B = B(2:3,:);
                
            end
            
        end
        
        
        function H = geth(this, x, y)
            % Get the flux density values associated with the points at X,Y
            % from the solution
            %
            % Syntax
            %
            % H = fpproc.geth(X, Y)
            %
            % Input
            %
            %   X,Y - X and Y are matrices of the same size containing
            %     sets of x and y coordinates at which the point properties
            %     are to be determined. Internally these will be reshaped
            %     as X(:),Y(:), i.e. two column vectors.
            %
            % Output
            %
            %   H - the magnetic field intensity at the requested
            %     coordinates
            %
            %
            
            if (nargin==3)
                
                H = this.getpointvalues(x,y);
                
                H = H(6:7,:);
                
            elseif (nargin==2)
                
                H = this.getpointvalues(x);
                
                H = H(6:7,:);
                
            end
            
        end
        
        function A = geta(this, x, y)
            % Get the vector potential values associated with the points at
            % X,Y from the solution
            %
            % Syntax
            %
            % A = fpproc.geta(X, Y)
            %
            % Input
            %
            %   X,Y - X and Y are matrices of the same size containing
            %     sets of x and y coordinates at which the point properties
            %     are to be determined. Internally these will be reshaped
            %     as X(:),Y(:), i.e. two column vectors.
            %
            % Output
            %
            %   A - the vector potential at the requested coordinates
            %
            %
            
            if (nargin==3)
                
                A = this.getpointvalues(x,y);
                
                A = A(1,:);
                
            elseif (nargin==2)
                
                A = this.getpointvalues(x);
                
                A = A(1,:);
                
            end
            
        end
        
        function smoothon(this)
            % turns on interpolation of point values in elements
            %
            % Syntax
            %
            % fpproc.smoothon()
            %
            % Description
            %
            % Controls whether or not smoothing is applied to the B and H
            % fields in each element when reporting point properties.
            %
            % The fields are naturally piece-wise constant over each mesh
            % element. Calling smoothon turns on smoothing. It can be
            % turned off using smoothoff.
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            fpproc_interface_mex('smoothon', this.objectHandle);
        end
        
        function smoothoff(this)
            % turns off interpolation of point values in elements
            %
            % Syntax
            %
            % fpproc.smoothoff()
            %
            % Description
            %
            % Controls whether or not smoothing is applied to the B and H
            % fields in each element when reporting point properties.
            %
            % The fields are naturally piece-wise constant over each mesh
            % element. Calling smoothon turns off smoothing. It can be
            % turned on using smoothon.
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            fpproc_interface_mex('smoothoff', this.objectHandle);
        end

        function clearcontour(this)
            % clears all currently entered contour points
            %
            % Syntax
            %
            % fpproc.clearcontour()
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            fpproc_interface_mex('clearcontour', this.objectHandle);
        end

        function varargout = addcontour(this, x, y)
            % add point to integration contour at point (x,y)
            %
            % Syntax
            %
            % fpproc.addcontour(x, y)
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            [varargout{1:nargout}] = fpproc_interface_mex('addcontour', this.objectHandle, x(:), y(:));
        end
        
        function varargout = lineintegral(this, type)
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            [varargout{1:nargout}] = fpproc_interface_mex('lineintegral', this.objectHandle, type);
        end
        
        function selectblock(this, x, y, clearselected)
            % select blocks based on position
            %
            % Syntax
            %
            % fpproc.selectblock(x, y)
            % fpproc.selectblock(x, y, clearselected)
            %
            % Input
            %
            %   x, y - x and y positions inside the blocks to be selected
            %
            %   clearselected - (optional) boolean flag determining whether
            %     any previous selection is cleared
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            if nargin < 4
                clearselected = false;
            end
            if clearselected
                this.clearblock();
            end
            fpproc_interface_mex('selectblock', this.objectHandle, x, y);
        end
        
        function groupselectblock(this, groupno, clearselected)
            % select blocks based on group membership
            %
            % Syntax
            %
            % fpproc.groupselectblock(groupno)
            %
            % Description
            %
            % Selects all blocks which are members of the supplied group
            % number(s). If groupno is empty, all blocks are selected.
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            if nargin < 3
                clearselected = false;
            end
            if clearselected
                this.clearblock();
            end
            if isempty (groupno)
                fpproc_interface_mex('groupselectblock', this.objectHandle, groupno);
            else
                for gpind = 1:numel(groupno)
                    fpproc_interface_mex('groupselectblock', this.objectHandle, groupno(gpind));
                end
            end
        end
        
        function selectallblocks(this)
            % selects mfemmdeps.every block in the solution
            %
            % Syntax
            %
            % fpproc.selectallblocks()
            %
            %
            
            this.groupselectblock([]);
            
        end
        
        function clearblock(this)
            % clears any existing block selection so no blocks are selected
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            fpproc_interface_mex('clearblock', this.objectHandle);
        end
        
        function int = blockintegral(this, type, x, y)
            % blockintegral calculate a block integral for the selected blocks
            %
            % Syntax
            %
            % int = fpproc.blockintegral(type)
            % int = fpproc.blockintegral(type, x, y)
            %
            % Description
            %
            % fpproc.blockintegral(type) peforms the desired integral on
            % the currently selected blocks.
            %
            % fpproc.blockintegral(type, x, y) clears any existing block
            % selection, selects the  the block closest to (x,y) and performs  
            % the integral on this block.
            %
            % NB: For planar simulations, many of the integrals will be
            % scaled by the problem depth, e.g. the 'A' integral, actually
            % reports int A x depth.
            %
            % Input
            %
            %  type - an integer flag determining the integral type to e
            %   perfomed. The following options are available:
            %
            %   0   A.J
            %   1   A
            %   2   Magnetic field energy
            %   3   Hysteresis and/or lamination losses
            %   4   Resistive losses
            %   5   Block cross-section area
            %   6   Total losses
            %   7   Total current
            %   8   Integral of Bx (or Br) over block
            %   9   Integral of By (or Bz) over block
            %   10  Block volume
            %   11  x (or r) part of steady-state Lorentz force
            %   12  y (or z) part of steady-state Lorentz force
            %   13  x (or r) part of 2x Lorentz force
            %   14  y (or z) part of 2x Lorentz force
            %   15  Steady-state Lorentz torque
            %   16  2X component of Lorentz torque
            %   17  Magnetic field coenergy
            %   18  x (or r) part of steady-state weighted stress tensor force
            %   19  y (or z) part of steady-state weighted stress tensor force
            %   20  x (or r) part of 2x weighted stress tensor force
            %   21  y (or z) part of 2x weighted stress tensor force
            %   22  Steady-state weighted stress tensor torque
            %   23  2X component of weighted stress tensor torque
            %   24  R2 (i.e. moment of inertia / density)
            %   25  2D shape centroid
            %
            % Output
            %
            %  int - reult of the integral operation
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            
            if nargin > 2
                if nargin == 3 || nargin > 4
                    error('Wrong number of input arguments.')
                else
                    if mfemmdeps.samesize(x, y)
                        % clear existing block selection
                        this.clearblock();
                        % select the specified blocks
                        for i = 1:numel(x)
                            this.selectblock(x(i), y(i), false)
                        end
                    else
                       error('x and y must be matrices of the same size.') 
                    end
                end
            end
            % perform the block integral
            int = fpproc_interface_mex('blockintegral', this.objectHandle, type);
            
        end
        
        function int = gapintegral(this, boundname, type)
            % gapintegral calculates integrals in an air gap region
            %
            % Syntax
            %
            % int = fpproc.gapintegral(boundname, type)
            %
            % Input
            %
            % type - an integer flag determining the integral type to be
            %  perfomed. The following options are available:
            %
            %   0   
            %
            % Output
            %
            %  
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            
            % perform the gap integral
            int = fpproc_interface_mex('gapintegral', this.objectHandle, boundname, type);
            
        end
        
        function varargout = getprobleminfo(this)
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            [varargout{1:nargout}] = fpproc_interface_mex('getprobleminfo', this.objectHandle);
        end
        
        function circprops = getcircuitprops(this, circuitname)
            % obtain information associated with a circuit in an mfemm
            % magnetics solution.
            %
            % Syntax
            %
            % circprops = fpproc.getcircuitprops(circuitname)
            %
            % Description
            %
            % Properties are returned for the circuit property named with
            % the name 'circuitname'.
            %
            % circprops is a vector of three values. In order, these values
            % are:
            %
            %  current:  Current carried by the circuit.
            %
            %  volts:    Voltage drop across the circuit in the circuit.
            %
            %  flux:     Circuit's flux linkage
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            
            circprops = fpproc_interface_mex('getcircuitprops', this.objectHandle, circuitname);
            
        end

        %%%%%%      Derived Methods        %%%%%%%
        
        function varargout = newcontour(this, x, y)
            % Clears exusting contour points and creates a new contour from
            % the supplied contour points
            %
            % Syntax
            %
            % newcontour(x, y)
            %
            % Description
            %
            % x and y are vectors of x and y positons making up the
            % contour. Once created the contour can be used to generate
            % line integrals etc.
            %
            %
            
            if ~this.isdocopen
                error('No solution document has been opened.')
            end
            
            if ~mfemmdeps.samesize(x,y) || ~isvector(x) || numel(x) < 2
                error('x and y must be vectors of at least two values.')
            end

            if numel(x) ~= numel(y)
                error('FPPROC:wrongsizeinputs', ...
                      'x and y must be the same size.');
            end
            if numel(x) < 2
                error('FPPROC:wrongsizeinputs', ...
                      'You must supply at least two contour coordinates.');
            end
            
            % clear out any existing contour points
            this.clearcontour();
            % create the new contour
            [varargout{1:nargout}] = this.addcontour(x(:), y(:));
            
        end
        
        function [R, L] = circuitRL(this, circuitname)
            % gets the inductance and resistance of a circuit in the
            % solution with name 'circuitname'
            %
            % Syntax
            %
            % [R, L] = fpproc.circuitRL(circuitname)
            %
            % Input
            %
            %   circuitname - the name of the circuit from which we wish to 
            %     obtain the inductance and resistance for
            % 
            % Output
            %
            %  R - circuit resistance
            %
            %  L - circuit inductance (calculated from Phi / I)
            %

            temp = this.getcircuitprops(circuitname);

            L = temp(3) / temp(1);

            R = temp(2) / temp(1);

        end
        
        function smooth(this, flag)
            % sets interpolation of point values to 'on' or 'off' dependent
            % on input flag
            %
            % Syntax
            %
            % fpproc.smooth(flag)
            %
            % Input
            %
            %   flag - string, either 'on' or 'off'
            %
            
            if ~ischar(flag)
                error('flag must be a string');
            end
            
            switch flag
                
                case 'on'
                    this.smoothon();
                    
                case 'off'
                    this.smoothoff()
                    
                otherwise
                    error('flag must be the string ''on'' or ''off''.')
                    
            end
            
        end
        
        function energy = totalfieldenergy(this)
            % calculates the total field energy in the solution domain
            
            % Select all blocks
            this.selectallblocks();

            % Extract the integral of the magnetic field energy
            energy = this.blockintegral(2);
            
        end
        
        function coenergy = totalfieldcoenergy(this)
            % calculates the total field coenergy in the solution domain
            
            % Select all blocks
            this.selectallblocks();

            % Extract the integral of the magnetic field coenergy
            coenergy = this.blockintegral(17);
            
        end
        
        
        function hfig = plotBfield(this, varargin)
%         function hfig = plotBfield(this, x, y, w, h, varargin)
            % creates a plot of the flux density vector field
            %
            % Syntax
            %
            % fpproc.plotBfield(x, y, w, h)
            % fpproc.plotBfield(x, y, w, h, 'Parameter', Value)
            % fpproc.plotBfield('Parameter', Value)
            %                   Without [x, y, w, h], plot is defined from
            %                   the problem extents (enlarged 10%)
            %
            % Cylindrical Coordinates:
            % fpproc.plotBfield(r, theta, r_length, th_width, 'PlotCylindrical', true)
            %
            % Input
            %
            %
            %   x - x (or r) coordinate lower left corner of region to be
            %     plotted (initial radius in cylindrical coordinates).
            % 
            %   y - y (or theta [°]) coordinate of  lower left corner of region to 
            %     be plotted (initial angle in cylindrical coordinates).
            %
            %   w - width of region to be plotted (radial length).
            % 
            %   h - height of region to be plotted (circunferential width [°]).
            %
            % Further options are supplied using parameter-value pairs,
            % the possible options are:
            %
            %   'Points' - determines the number of points that will be
            %              plotted using method 0. If points is a scalar, 
            %              a grid of this number of points on both sides 
            %              will be created. If points is a two element 
            %              vector it will be the number of points in the 
            %              x and y direction respectively. 
            %              (Default is 40)
            % 
            %    'PlotNodes' - determines if nodes are drawn when
            %                  plotting the femmproblem
            %
            %    'Density' - determines the density of the interpolation
            %                for plot using method 1.
            %                (Default is 250)
            %
            %    'FluxLines' - the number of flux lines 
            %                  (Default is 19)
            %    'ShowFlux' - plot flux lines. (Default is true) 
            %
            %    'Method' - Method 0 for a vector field plot using 
            %               coloured arrows.
            %               Method 1 for a density plot of the
            %               magnitude of the magnetic field.
            %
            %    'PlotCylindrical' - Plot problem in cylindrical coordinates.
            %               It helps increase proble resolution by
            %               evaluating only in the adequate region
            %               (Default is false)
            %
            %
            
            % New, the function can be called without [x,y,w,h]
            if numel(varargin) < 4 || ~all(cellfun('isclass', varargin(1:4), 'double'))
                % If plot extent is not defined, define here:
                [x,y,w,h] = extent_mfemm(this.FemmProblem);
                % Extent the problem 10%:
                del_w = 0.1*w;
                del_h = 0.1*h;
                w = w + del_w;
                h = h + del_h;
                x = x - del_w/2;
                y = y - del_h/2;
                
                aux_flag = 1;
            
            else
                x = varargin{1};
                y = varargin{2};
                w = varargin{3};
                h = varargin{4};
                
                varargin = varargin(5:end);
                
                aux_flag = 0;
            end
            
            Inputs.Points = 40;
            Inputs.Density = 250;
            Inputs.FluxLines = 19;
            Inputs.ShowFlux = true;
            Inputs.Method = 0;
            Inputs.PlotCylindrical = false;
            Inputs.PlotNodes = false;
            Inputs.AddLabels = false;
            
            Inputs = mfemmdeps.parseoptions (Inputs, varargin);
            
            if aux_flag && Inputs.PlotCylindrical
                error('ERROR%s \nPlease use the correct syntax \nplotBfield(r, theta, r_length, th_width, ´PlotCylindrical´, true)','!!');
            end
            
            datafcn = @this.getb;
            
            hfig = this.plotvectorfield(datafcn, x, y, w, h, Inputs);
            
            % Added this to plot flux contours in the B density plot
            if Inputs.Method == 1 && Inputs.ShowFlux
                
                datafcn = @(x,y) reshape (this.geta (x,y), size (x));
                
%                 Figure is Parent of Axes, can be called from hax.Parent.
%                           or, Axis can be called from hfig.CurrentAxes

                Inputs.FigureHandle = hfig;

                hfig = this.plotscalarfield (datafcn, x, y, w, h, Inputs);
                
            end
            
            
            if ~isempty (this.FemmProblem)
                if Inputs.PlotCylindrical
                    % Since the plotfemmproblem() still treats [x, y, w, h]
                    % This here is to adjust the plot extent with
                    % cylindrical inputs.
                    
                    d_ang = h*pi/180;
                    ang = y*pi/180;
                    r = x + w;
                    x = r*cos(ang + d_ang);
                    
                    if x > 0
                        x = 0;
                    end
                    
                    w = r*cos(ang) - x;
                    
                    y = 0;
                    h = r*sin(ang + d_ang);
                    
                    if d_ang > pi/2
                        h = r*sin(pi/2);
                    end
                        
                end
                
                hfig = plotfemmproblem(this.FemmProblem, ...
                                    'PlotNodes', Inputs.PlotNodes, ...
                                    'InitialViewPort', [x,y,w,h], ...
                                    'AddLabels', Inputs.AddLabels, ...
                                    'FigureHandle', hfig);
            else
              hfig = figure;
            end
            
            title ('Magnetic Flux Density, B');
            
        end

        
        function hfig = plotHfield(this, varargin)
            % creates a plot of the magnetic intensity vector field
            %
            % Syntax
            %
            % fpproc.plotHfield(x, y, w, h)
            % fpproc.plotHfield(x, y, w, h, 'Parameter', Value)
            % fpproc.plotHfield('Parameter', Value)
            %                   Without [x, y, w, h], plot is defined from
            %                   the problem extents (enlarged 10%)
            %
            % Cylindrical Coordinates:
            % fpproc.plotHfield(r, theta, r_length, th_width, 'PlotCylindrical', true)
            %
            % Input
            %
            %
            %   x - x (or r) coordinate lower left corner of region to be
            %     plotted (initial radius in cylindrical coordinates).
            % 
            %   y - y (or theta [°]) coordinate of  lower left corner of region to 
            %     be plotted (initial angle in cylindrical coordinates).
            %
            %   w - width of region to be plotted (radial length).
            % 
            %   h - height of region to be plotted (circunferential width [°]).
            %
            % Further options are supplied using parameter-value pairs,
            % the possible options are:
            %
            %   'Points' - determines the number of points that will be
            %              plotted using method 0. If points is a scalar, 
            %              a grid of this number of points on both sides 
            %              will be created. If points is a two element 
            %              vector it will be the number of points in the 
            %              x and y direction respectively. 
            %              (Default is 40)
            % 
            %    'PlotNodes' - determines if nodes are drawn when
            %                  plotting the femmproblem
            %
            %    'Density' - determines the density of the interpolation
            %                for plot using method 1.
            %                (Default is 250)
            %
            %    'FluxLines' - the number of flux lines 
            %                  (Default is 19)
            %    'ShowFlux' - plot flux lines. (Default is true) 
            %
            %    'Method' - plot method use 0 for a vector field plot using
            %               coloured arrows. Use 1 for a density plot of the
            %               magnitude of the magnetic field.
            %
            %    'PlotCylindrical' - Plot problem in cylindrical coordinates.
            %               It helps increase proble resolution by
            %               evaluating only in the adequate region
            %               (Default is false)
            %
            
            % New, the function can be called without [x,y,w,h]
            if numel(varargin) < 4 || ~all(cellfun('isclass', varargin(1:4), 'double'))
                % If plot extent is not defined, define here:
                [x,y,w,h] = extent_mfemm(this.FemmProblem);
                % Extent the problem 10%:
                del_w = 0.1*w;
                del_h = 0.1*h;
                w = w + del_w;
                h = h + del_h;
                x = x - del_w/2;
                y = y - del_h/2;
                
                aux_flag = 1;
            
            else
                x = varargin{1};
                y = varargin{2};
                w = varargin{3};
                h = varargin{4};
                
                varargin = varargin(5:end);
                
                aux_flag = 0;
            end
            
            Inputs.Points = 40;
            Inputs.Density = 250;
            Inputs.FluxLines = 19;
            Inputs.ShowFlux = true;
            Inputs.Method = 0;
            Inputs.PlotCylindrical = false;
            Inputs.PlotNodes = false;
            Inputs.AddLabels = false;
            
            Inputs = mfemmdeps.parseoptions (Inputs, varargin);
            
            if aux_flag && Inputs.PlotCylindrical
                error('ERROR%s \nPlease use the correct syntax \nplotBfield(r, theta, r_length, th_width, ´PlotCylindrical´, true)','!!');
            end
            
            datafcn = @this.geth;
            
            hfig = this.plotvectorfield(datafcn, x, y, w, h, Inputs);
            
            if ~isempty (this.FemmProblem)
                if Inputs.PlotCylindrical
                    % Since the plotfemmproblem() still treats [x, y, w, h]
                    % This here is to adjust the plot extent with
                    % cylindrical inputs.
                    
                    d_ang = h*pi/180;
                    ang = y*pi/180;
                    r = x + w;
                    x = r*cos(ang + d_ang);
                    
                    if x > 0
                        x = 0;
                    end
                    
                    w = r*cos(ang) - x;
                    
                    y = 0;
                    h = r*sin(ang + d_ang);
                    
                    if d_ang > pi/2
                        h = r*sin(pi/2);
                    end
                        
                end
              hfig = plotfemmproblem(this.FemmProblem, ...
                                    'PlotNodes', Inputs.PlotNodes, ...
                                    'InitialViewPort', [x,y,w,h], ...
                                    'AddLabels', Inputs.AddLabels, ...
                                    'FigureHandle', hfig);
            else
              hfig = figure;
            end
            
            title ('Magnetic Intensity Field, H');
            
        end
        
        
        function hfig = plotAfield(this, varargin)
            % creates a plot of the magneticvector potential scalar field
            %
            % Syntax
            %
            % fpproc.plotAfield(x, y, w, h)
            % fpproc.plotAfield(x, y, w, h, 'Parameter', Value)
            % fpproc.plotAfield('Parameter', Value)
            %                   Without [x, y, w, h], plot is defined from
            %                   the problem extents (enlarged 10%)
            %
            % Cylindrical Coordinates:
            % fpproc.plotHfield(r, theta, r_length, th_width, 'PlotCylindrical', true)
            %
            % Input
            %
            %
            %   x - x (or r) coordinate lower left corner of region to be
            %     plotted (initial radius in cylindrical coordinates).
            % 
            %   y - y (or theta [°]) coordinate of  lower left corner of region to 
            %     be plotted (initial angle in cylindrical coordinates).
            %
            %   w - width of region to be plotted (radial length).
            % 
            %   h - height of region to be plotted (circunferential width [°]).
            %
            % Further options are supplied using parameter-value pairs,
            % the possible options are:
            % 
            %    'PlotNodes' - determines if nodes are drawn when
            %                  plotting the femmproblem
            %    'AddLabels' - determines if labes are drown when
            %                  plotting the femmproblem
            %
            %    'Density' - determines the density of the interpolation
            %                for plot using method 1.
            %                (Default is 250)
            %
            %    'FluxLines' - the number of flux lines 
            %                  (Default is 19)
            %    'ShowFlux' - plot flux lines. (Default is true) 
            %
            %    'Method' - Method 0 for a filled contour plot.
            %               Method 1 is used by plotBfield or plotHfield to 
            %               add flux lines.
            %
            %    'PlotCylindrical' - Plot problem in cylindrical coordinates.
            %               It helps increase proble resolution by
            %               evaluating only in the adequate region
            %               (Default is false)
            %
            
            % New, the function can be called without [x,y,w,h]
            if numel(varargin) < 4 || ~all(cellfun('isclass', varargin(1:4), 'double'))
                % If plot extent is not defined, define here:
                [x,y,w,h] = extent_mfemm(this.FemmProblem);
                % Extent the problem 10%:
                del_w = 0.1*w;
                del_h = 0.1*h;
                w = w + del_w;
                h = h + del_h;
                x = x - del_w/2;
                y = y - del_h/2;
            
            else
                x = varargin{1};
                y = varargin{2};
                w = varargin{3};
                h = varargin{4};
                
                varargin = varargin(5:end);
            end
            
%             Inputs.Points = 40;
            Inputs.Density = 250;
            Inputs.FluxLines = 19;
            Inputs.ShowFlux = true;
            Inputs.PlotCylindrical = false;
            Inputs.Method = 0;
            Inputs.PlotNodes = false;
            Inputs.AddLabels = false;
            
            Inputs = mfemmdeps.parseoptions (Inputs, varargin);
            
            if Inputs.Method >= 1
                error('ERROR%s \nMethod not supported.','!!');
            end
            
            datafcn = @(x,y) reshape (this.geta (x,y), size (x));
            
            hfig = this.plotscalarfield (datafcn, x, y, w, h, Inputs);
            
            
            if ~isempty (this.FemmProblem)
                if Inputs.PlotCylindrical
                    % Since the plotfemmproblem() still treats [x, y, w, h]
                    % This here is to adjust the plot extent with
                    % cylindrical inputs.
                    
                    d_ang = h*pi/180;
                    ang = y*pi/180;
                    r = x + w;
                    x = r*cos(ang + d_ang);
                    
                    if x > 0
                        x = 0;
                    end
                    
                    w = r*cos(ang) - x;
                    
                    y = 0;
                    h = r*sin(ang + d_ang);
                    
                    if d_ang > pi/2
                        h = r*sin(pi/2);
                    end
                        
                end
              hfig = plotfemmproblem(this.FemmProblem, ...
                                    'PlotNodes', Inputs.PlotNodes, ...
                                    'InitialViewPort', [x,y,w,h], ...
                                    'AddLabels', Inputs.AddLabels, ...
                                    'FigureHandle', hfig);
            else
              hfig = figure;
            end
            
            title ('Vector Potential');
            
        end
        
        function n = nummeshnodes (this)
            % return the number of nodes in the mesh
            n = fpproc_interface_mex('numnodes', this.objectHandle);
        end
        
        function n = numelements (this)
            % return the number of elements in the mesh
            n = fpproc_interface_mex('numelements', this.objectHandle);
        end
        
        function vert = getvertices (this, n)
            % returns vertex locations for elements
            %
            % Syntax
            %
            % vert = getvertices ()
            % vert = getvertices (n)
            %
            % Input
            %
            % n - optional matrix of element numbers for which to obtain
            %   the vertices. Element numbers start from 1 (rather than
            %   zero). The vertices of mfemmdeps.every mesh element are returned if n
            %   is not supplied.
            %
            % Output
            % 
            % vert - matrix of (n x 6) values. Each row containing the  
            %   coordinates for the vertices of each element number in 'n'
            %   such that a row conatins:
            %
            %       [ x1, y1, x2, y2, x3, y3 ]
            %         
            %
            
            if nargin < 2
                n = 1:this.numelements ();
            end
            
            vert = fpproc_interface_mex('getvertices', this.objectHandle, n(:));
        
        end
         
        function elm = getelements (this, n)
            % returns information about elements
            %
            % Syntax
            %
            % elm = getelements ()
            % elm = getelements (n)
            %
            % Input
            %
            % n - optional matrix of element numbers for which to obtain information. 
            %   Element numbers start from 1 (rather than zero). If omitted
            %   information on mfemmdeps.every mesh element is returned.
            %
            % Output
            % 
            % elm - matrix of (n x 7) values. Each row containing the following 
            %   information for each element number in 'n':
            %         1. One-based Index of first element node
            %         2. One-based Index of second element node
            %         3. One-based Index of third element node
            %         4. x (or r) coordinate of the element centroid
            %         5. y (or z) coordinate of the element centroid
            %         6. element area using the length mfemmdeps.unit defined for the problem
            %         7. group number associated with the element
            %
            
            if nargin < 2
                n = 1:this.numelements ();
            end
            
            elm = fpproc_interface_mex('getelements', this.objectHandle, n(:));
        
        end
        
        function centr = getcentroids (this, n)
            % returns centroid locations for elements
            %
            % Syntax
            %
            % centr = getcentroids ()
            % centr = getcentroids (n)
            %
            % Input
            %
            % n - optional matrix of element numbers for which to obtain
            %   the centroids. Element numbers start from 1 (rather than
            %   zero). The centroids of mfemmdeps.every mesh element are returned if
            %   n is not supplied.
            %
            % Output
            % 
            % centr - matrix of (n x 2) values. Each row containing the  
            %   coordinates for the vertices of each element number in 'n'
            %   such that a row conatins:
            %
            %       [ x, y ]
            %         
            %
            
            if nargin < 2
                n = 1:this.numelements ();
            end
            
            centr = fpproc_interface_mex('getcentroids', this.objectHandle, n(:));
        
        end
        
        function areas = getareas (this, n)
            % returns area information about elements
            %
            % Syntax
            %
            % areas = getareas ()
            % areas = getareas (n)
            %
            % Input
            %
            % n - optional matrix of element numbers for which to obtain
            %   the areas. Element numbers start from 1 (rather than
            %   zero). The areas of mfemmdeps.every mesh element are returned if
            %   n is not supplied.
            %
            % Output
            % 
            % areas - matrix of (n x 1) values. Each row containing the  
            %   area for the element number in 'n'.
            %
            
            if nargin < 2
                n = 1:this.numelements ();
            end
            
            areas = fpproc_interface_mex('getareas', this.objectHandle, n(:));
        
        end
        
        function vols = getvolumes (this, n)
            % returns area information about elements
            %
            % Syntax
            %
            % areas = getvolumes ()
            % areas = getvolumes (n)
            %
            % Input
            %
            % n - optional matrix of element numbers for which to obtain
            %   the getvolumes. Element numbers start from 1 (rather than
            %   zero). The areas of mfemmdeps.every mesh element are returned if
            %   n is not supplied.
            %
            % Output
            % 
            % vols - matrix of (n x 1) values. Each row containing the  
            %   volume for the element number in 'n'.
            %
            
            if nargin < 2
                n = 1:this.numelements ();
            end
            
            vols = fpproc_interface_mex('getareas', this.objectHandle, n(:));
        
        end
        
        function n = numgroupelements (this, groupno)
            % returns number of elements in groups
            %
            % Syntax
            %
            % n = numgroupelements (groupno)
            %
            % Input
            %
            % groupno - matrix of group numbers for which to obtain
            %   the number of element.
            %
            % Output
            % 
            % n - matrix of numbers of elements, one for each number in
            %   groupno.
            %         
            %
            
            if nargin ~= 2
                error ('You must supply a group number.')
            end
            
            n = zeros (size(groupno));
            
            for ind = 1:numel(groupno) 
                n(ind) = fpproc_interface_mex('numgroupelements', this.objectHandle, groupno(ind));
            end
            
        end
        
        function vert = getgroupvertices (this, groupno)
            % returns vertex locations for elements in groups
            %
            % Syntax
            %
            % vert = getgroupvertices (groupno)
            %
            % Input
            %
            % groupno - matrix of group numbers for which to obtain
            %   the element vertices.
            %
            % Output
            % 
            % vert - matrix of (n x 6) values. Each row containing the  
            %   coordinates for the vertices of each element such that a
            %   row conatins:
            %
            %       [ x1, y1, x2, y2, x3, y3 ]
            %         
            %
            
            if nargin ~= 2
                error ('You must supply a group number.')
            end
            
            vert = [];
            
            for ind = 1:numel(groupno)
                
                vert = [vert; fpproc_interface_mex('getgroupvertices', this.objectHandle, groupno(ind))];
            
            end
        
        end
         
        function elm = getgroupelements (this, groupno)
            % returns information about elements in groups
            %
            % Syntax
            %
            % elm = getelements (groupno)
            %
            % Input
            %
            % groupno - matrix of group numbers for which to obtain
            %   information about mesh elements.
            %
            % Output
            % 
            % elm - matrix of (n x 7) values. Each row containing the following 
            %   information for each element:
            %         1. One-based Index of first element node
            %         2. One-based Index of second element node
            %         3. One-based Index of third element node
            %         4. x (or r) coordinate of the element centroid
            %         5. y (or z) coordinate of the element centroid
            %         6. element area using the length mfemmdeps.unit defined for the problem
            %         7. group number associated with the element
            %
            
            if nargin ~= 2
                error ('You must supply a group number.')
            end
            
            elm = [];
            
            for ind = 1:numel(groupno)
                
                elm = [elm; fpproc_interface_mex('getgroupelements', this.objectHandle, groupno(ind))];
                
            end
        
        end
        
        function centr = getgroupcentroids (this, groupno)
            % returns centroid locations for elements in groups
            %
            % Syntax
            %
            % centr = getcentroids (groupno)
            %
            % Input
            %
            % groupno - optional matrix of group numbers for which to obtain
            %   the element centroids.
            %
            % Output
            % 
            % centr - matrix of (n x 2) values. Each row containing the  
            %   coordinates for the vertices of each element such that a
            %   row contains:
            %
            %       [ x, y ]
            %         
            %
            
            if nargin ~= 2
                error ('You must supply a group number.')
            end
            
            centr = [];
            
            for ind = 1:numel(groupno)
                
                centr = [centr; fpproc_interface_mex('getgroupcentroids', this.objectHandle, groupno(ind))];
            end
        
        end
        
        function areas = getgroupareas (this, groupno)
            % returns area information about elements in groups
            %
            % Syntax
            %
            % areas = getgroupareas (groupno)
            %
            % Input
            %
            % groupno - optional matrix of group numbers for which to obtain
            %   the element areas. 
            %
            % Output
            % 
            % areas - matrix of of areas.
            %
            
            if nargin ~= 2
                error ('You must supply a group number.')
            end
            
            areas = [];
            
            for ind = 1:numel(groupno)
            
                areas = [areas; fpproc_interface_mex('getgroupareas', this.objectHandle, groupno(ind))];
            
            end
        
        end
        
        function vols = getgroupvolumes (this, groupno)
            % returns area information about elements in groups
            %
            % Syntax
            %
            % areas = getgroupvolumes (groupno)
            %
            % Input
            %
            % groupno - optional matrix of group numbers for which to obtain
            %   the element volumes. 
            %
            % Output
            % 
            % vols - matrix of of volumes.
            %
            
            if nargin ~= 2
                error ('You must supply a group number.')
            end
            
            vols = [];
            
            for ind = 1:numel(groupno)
            
                vols = [vols; fpproc_interface_mex('getgroupvolumes', this.objectHandle, groupno(ind))];
            
            end
        
        end
        
        function B = getgapb(this, bound_name, angles)
            % Get the flux density values for air gap boundary at specified angles
            %
            % Syntax
            %
            % B = fpproc.getgapb(X, Y)
            %
            % Input
            %
            %   bound_name - name of the air gap boundary for which the
            %    flux density is to be evaluated
            %
            %   angle - angle is  containinga set of angles along the
            %    centerline of an air gap boundary region at which the flux
            %    density is to be determined. Internally this will be
            %    reshaped as angles(:) i.e. a column vector.
            %
            % Output
            %
            %   B - (n x 2) matrix containing the radial and tangential 
            %    flux density at the requested angles in the specified air
            %    gap region
            %
            %
            
            B = nan * ones (numel(angles), 2);
            
            for ind = 1:numel(angles)
            
                [Br, Bt] = fpproc_interface_mex('getgapb', this.objectHandle, bound_name, angles(ind));
                
                B(ind,1:2) = [Br, Bt];
            
            end
            
        end
        
        function B = getgapa(this, bound_name, angles)
            % Get the vector potential values for air gap boundary at specified angles
            %
            % Syntax
            %
            % B = fpproc.getgapa(X, Y)
            %
            % Input
            %
            %   bound_name - name of the air gap boundary for which the
            %    flux density is to be evaluated
            %
            %   angle - angle is  containinga set of angles along the
            %    centerline of an air gap boundary region at which the flux
            %    density is to be determined. Internally this will be
            %    reshaped as angles(:) i.e. a column vector.
            %
            % Output
            %
            %   B - (n x 2) matrix containing the radial and tangential 
            %    flux density at the requested angles in the specified air
            %    gap region
            %
            %
            
            B = nan * ones (numel(angles), 2);
            
            for ind = 1:numel(angles)
            
                [Br, Bt] = fpproc_interface_mex('getgapa', this.objectHandle, bound_name, angles(ind));
                
                B(ind,1:2) = [Br, Bt];
            
            end
            
        end
        
        function nh = numgapharmonics (this, bound_name)
            % Get the number of harmonics for an air gap boundary
            %
            % Syntax
            %
            % nh = fpproc.numgapharmonics (bound_name)
            %
            % Input
            %
            %   bound_name - name of the air gap boundary for which the
            %    number of harmonics is to be returned
            %
            % Output
            %
            %   nh - scalar value, the number of harmonics for this air gap
            %     boundary
            %
            %
            
            nh = fpproc_interface_mex ('numgapharmonics', this.objectHandle, bound_name);
            
        end
        
        function [acc, acs, brc, brs, btc, bts] = getgapharmonics (this, bound_name, n)
            % get values of harmonics of air gap boundary
            %
            % Syntax
            %
            % [acc, acs, brc, brs, btc, bts] = fpproc.getgapharmonics (bound_name, n)
            %
            % Input
            %
            %   bound_name - name of the air gap boundary for which the
            %    flux density is to be evaluated
            %
            %   n - harmonic number
            %
            % Output
            %
            %   acc - 
            %
            %   acs - 
            %
            %   brc - 
            %
            %   brs - 
            %
            %   btc - 
            %
            %   bts - 
            %
            %
            
            
            acc = nan * ones (numel(n), 1); 
            acs = acc;
            brc = acc;
            brs = acc;
            btc = acc;
            bts = acc;
            
            for ind = 1:numel(n)
            
                [acc(ind,1), acs(ind,1), brc(ind,1), brs(ind,1), btc(ind,1), bts(ind,1)] ...
                    = fpproc_interface_mex('getgapharmonics', this.objectHandle, bound_name, n(ind));
            
            end
            
        end
        
        
    end
    
end
