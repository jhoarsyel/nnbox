classdef MultiLayerNet < handle & AbstractNet
    % MultiLayerNet Stack of neural networks
    %   Stores stacked network with interconnected inputs and outputs
    
    properties
        nets = {};
        frozenBelow = 0;
    end
    
    methods
        
        % AbstractNet Implementation ******************************************
        
        function S = insize(self)
            S = self.nets{1}.insize();
        end
        
        function S = outsize(self)
            S = self.nets{end}.outsize();
        end
        
        function [Y, A] = compute(self, X)
            nbNets = length(self.nets);
            
            if nargout > 1
                computeA = true;
                A = cell(nbNets, 1);
            else
                computeA = false;
            end
            
            for o = 1:nbNets
                if computeA
                    [X, A{o}] = self.nets{o}.compute(X);
                else
                    X = self.nets{o}.compute(X);
                end
            end
            Y = X;
        end % compute(X)
        
        function [] = pretrain(self, X)
            for o = self.frozenBelow + 1:length(self.nets)
                self.nets{o}.pretrain(X);
                X = self.nets{o}.compute(X);
            end
        end
        
        function [G, inErr] = backprop(self, A, outErr)
            G     = cell(length(self.nets), 1);
            inErr = [];
            % Backprop and compute gradient
            for l = length(self.nets):-1:self.frozenBelow + 1
                [G{l}, outErr] = self.nets{l}.backprop(A{l}, outErr);
            end
            if nargout == 2
                % Backprop through frozen layers
                for l = self.frozenBelow:-1:1
                    [~, outErr] = self.nets{l}.backprop(A{l}, outErr);
                end
                inErr = outErr;
            end
        end
        
        function [] = gradientupdate(self, G)
            for l = length(self.nets):-1:self.frozenBelow + 1
                self.nets{l}.gradientupdate(G{l});
            end
        end
        
        % Methods *************************************************************
        
        function [] = add(self, net)
            % ADD Stack an additional network on top
            %   [] = ADD(self, net) add net (an implementation of
            %   AbstractNet) on top of the networks currently in self.
            %   Input size of net must match the current output size of the
            %   multilayer network.
            assert(isa(net, 'AbstractNet'), 'net must implement AbstractNet');
%             TODO: check size compatibility (even for groups of neurons)
%             assert(isempty(self.nets) || ...
%                 all(self.outsize() == net.outsize), ...
%                 'self and net should have equal sizes');
            
            nbNets                    = length(self.nets) + 1;
            self.nets{nbNets}         = net.copy();
        end % add(self, net)
        
        function [] = freezeBelow(self, varargin)
            % FREEZEBELOW(l) Freeze bottom layers weights
            %   FREEZEBELOW(l) disables pretraining and gradient update on
            %   the l bottom layers of the network
            %   
            %   FREEZEBELOW() unfreezes all layers.
            if ~isempty(varargin)
                self.frozenBelow = varargin{1};
            else
                self.frozenBelow = 0;
            end
        end
        
    end % methods
    
    methods(Access = protected)
        
        % Override copyElement method
        function copy = copyElement(self)
            copy = MultiLayerNet();
            copy.nets = cell(size(self.nets));
            for i = 1:numel(self.nets)
                copy.nets{i} = self.nets{i}.copy();
            end
        end
        
    end
    
end % MultiLayerNet