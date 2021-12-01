function output = conv_encode(input, A)
%Encodes a row-vector input by (n,k,N)-code, returns the encoded signal.
%Input: input = bit-sequence to be encoded
%       A = convolution encoding projection matrix. For example, [1,1;1,0] results in
%       a (2, 1, 2)-code encoding process

    output = [];
    n = size(A,1); %Number of output bits
    k = 1; %Number of input bits
    N = size(A,2); %Number of Nodes
    state = zeros(N,1)'; %Represents the state of each node, there are in total N nodes.
    input = [input, zeros(k*(N-1),1)']; %Append shouwei-signal to the input signal
    
    %Start of the encoding process
    for i = 1:length(input) %Traverse the input signal per bit
        state = circshift(state, 1); %Cycle the current states one state down
        state(1) = input(i);    %Set the first state to the current bit
        symbols = zeros(n, 1)'; %Symbols is a row-vector that represents the output symbols corresponding to the current input bit and states
        for j = 1:n
            %Apply the projection matrix to the current states
            %and calculate the output symbols
            symbols(j) = mod(sum(state.*A(j,:)),2); 
        end
        output = [output, symbols];
    end
    %End of the encoding process
end