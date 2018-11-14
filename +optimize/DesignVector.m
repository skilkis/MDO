classdef DesignVector < dynamicprops & handle
    %DESIGNVECTOR Utility class allowing key, value pairs
    %   Solves the hassle of having to remember indices w/ fmincon

    properties
        init                % Initial Values of the Design Vector
        vector              % Current Design Vector (Normalized)
    end
    
    properties (SetAccess = private, GetAccess = private)
        keys                % Design Vector Keys
        cell_in             % Input cell containing key, value pairs
        lengths             % Lengths of each value to support arrays
    end
    
    properties (SetAccess = private)
        lb                  % Normalized Lower Bounds of Design Variable
        ub                  % Normalized Upper Bound of Design Variable
        history = []        % Stores previous values of the solver
    end
    
    methods
        
       % TODO add validator to check if correct inputs are provided
       % TODO add validator to check lb < ub
        function obj = DesignVector(cell_in)
            
            obj.cell_in = cell_in;
            obj.keys = cell_in(:,1);
            obj.lengths = cellfun(@(x) length(x), cell_in(:,2));
            obj.init = cat(2, obj.cell_in{:,2})'; 
            obj.vector = obj.init ./ obj.init; % Normalized
            obj.lb = cell2mat(cell_in(:,3));
            obj.ub = cell2mat(cell_in(:,4));
            
            key_idx = 1;
            vec_idx = 1; % Look-up index from 
            for key = obj.keys'
                % Creating a getter for each key
                len = obj.lengths(key_idx);
                P = addprop(obj, key{:});
                P.GetMethod = @(getter) ...
                    obj.vector(vec_idx:(vec_idx + len - 1)) .* ...
                    obj.init(vec_idx:(vec_idx + len - 1));
                % TODO experiment with set method
%                 P.SetMethod = @(setter) ...
%                     obj.vector(index:(index + len - 1)) .* ...
%                     obj.init(index:(index + len - 1));
                key_idx = key_idx + 1;
                vec_idx = vec_idx + len;
            end
        end
        
        function update(obj, vector)
            obj.history = [obj.history, obj.vector];
            obj.vector = vector;
        end
        
        function history = fetch_history(obj, varargin)
            % Fetches the history of the design vector from obj.history
            % and returns either the normalized or unormalized result
            % depending on user input
            %
            % Return Normalized History (Default behavior w/o argument):
            % obj.fetch_history('normalized', true)
            %
            % Return Proper History
            % obj.fetch_history('normalized', false)
            % 
            % Usage w/o arguments returns normalized history
            % obj.fetch_history()
            
            %Parsing arguments
            arg = inputParser; % Analyzes passed arguments
            addOptional(arg, 'normalized', true, @islogical);
            parse(arg, varargin{:});
            normalized = arg.Results.normalized;
            
            % Fetching desired history
            fetched_array = [obj.history, obj.vector];
            if normalized
                history = fetched_array;
            else
                history = fetched_array .* obj.init;
            end
        end
            
            

    %  function obj = DesignVector(data, keys)
    %      if nargin == 0
    %         data = 0;
    %         keys = '';
    %      elseif nargin == 1
    %         keys = '';
    %      end
    %      obj = obj@double(data);
    %      obj.keys = keys;
    %   end
   
%       function sref = subsref(obj,s)
%         switch s(1).type
%            case '.'
%               switch s(1).subs
%                  case 'keys'
%                     sref = obj.keys;
%                  case 'Data'
%                     d = double(obj);
%                     if length(s)<2
%                        sref = d;
%                     elseif length(s)>1 && strcmp(s(2).type,'()')
%                        sref = subsref(d,s(2:end));
%                     end
%                  otherwise
%                     error('Not a supported indexing expression')
%               end
%            case '()'
%               d = double(obj);
%               newd = subsref(d,s(1:end));
%               sref = definitions.DesignVector(newd,obj.keys);
%            case '{}'
%               error('Not a supported indexing expression')
%         end
%      end
     
%      function obj = subsasgn(obj,s,b)
%         switch s(1).type
%            case '.'
%               switch s(1).subs
%                  case 'keys'
%                     obj.keys = b;
%                  case 'Data'
%                     if length(s)<2
%                        obj = definitions.DesignVector(b,obj.keys);
%                     elseif length(s)>1 && strcmp(s(2).type,'()')
%                        d = double(obj);
%                        newd = subsasgn(d,s(2:end),b);
%                        obj = definitions.DesignVector(newd,obj.keys);
%                     end
%                  otherwise
%                     error('Not a supported indexing expression')
%               end
%            case '()'
%               d = double(obj);
%               newd = subsasgn(d,s(1),b);
%               obj = definitions.DesignVector(newd,obj.keys);
%            case '{}'
%               error('Not a supported indexing expression')
%         end
%      end
     
%      function newobj = horzcat(varargin)
%         d1 = cellfun(@double,varargin,'UniformOutput',false );
%         data = horzcat(d1{:});
%         str = horzcat(cellfun(@char,varargin,'UniformOutput',false));
%         newobj = definitions.DesignVector(data,str);
%      end
     
%      function newobj = vertcat(varargin)
%         d1 = cellfun(@double,varargin,'UniformOutput',false );
%         data = vertcat(d1{:});
%         str = vertcat(cellfun(@char,varargin,'UniformOutput',false));
%         newobj = definitions.DesignVector(data,str);
%      end
     
%      function str = char(obj)
%         str = obj.keys;
%      end
     
%      function disp(obj)
%         disp(obj.keys)
%         disp(double(obj))
%      end
  end
end
