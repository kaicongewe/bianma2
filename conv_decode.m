function output = conv_decode(input, A, type)
%Use Viterbi to decode the input sequence, return decoded sequence
%Inputs: input = inputted bit sequence
%        A = convolution encoding projection matrix (See conv_encode)
%        type = 'hard' if Hard Viterbi, 'soft' if Soft Viterbi
    n = size(A,1); % n/k is the number of output bits per input bit
    k = size(A,3); 
    N = size(A,2)-1; %Number of States
    input_length = length(input)/n; %How many bits did the original sequence have?
    shouwei = k*(N+1); %How many bits are used for shouwei?
    
    %Set up node net
    nodes(2^N, input_length) = Viterbi_Node;
    for i = 1:2^N
        for j = 1:input_length
            nodes(i, j).state = mydec2bin(i-1,N);   
        end
    end
    nodes(1,1).distance = 0; %Set distance of first node to 2
    connection_net = zeros(2^N, 2); %Connection net between nodes, 1st col is if input is 0, 2nd col is if input is 1
    connection_net(:,1) = [1:2:2^N, 1:2:2^N]; %Tip: write these connections out and you will see the pattern
    connection_net(:,2) = [2:2:2^N, 2:2:2^N];
    
    if type == 'hard' %Hard Viterbi
        input = input >= 0.5; %Round input
    elseif type == 'soft' %Soft Viterbi
        %Do nothing
    end
        
    for j = 1:input_length-1 %Every Column
        realin = input(1+((j-1)*n):(j*n));
        for i = 1:2^N %Every row
            state = nodes(i,j).state;
            for k = [0,1]
                curr_state = [k, flip(state)]; %Due to the way in which the state is noted in the node class, we have to use flip()
                expected = zeros(n,1)'; %Expected outcome with given state and input k
                for l = 1:n
                    %Apply the projection matrix to the current states
                    %and calculate the expected output symbols
                    expected(l) = mod(sum(curr_state.*A(l,:)),2);
                end
                d = distance(realin, expected); %Calculate distance, the smaller the better
                
                next_node_idx = connection_net(i, k+1); %Corresponding next node
                %If the new distance is less than the old distance, then we
                %can replace the old distance, since we have found a better
                %route to said node.
                if nodes(next_node_idx, j+1).distance > (nodes(i, j).distance + d)
                    nodes(next_node_idx, j+1).distance = nodes(i, j).distance + d;
                    nodes(next_node_idx, j+1).prev_node = i; %Change prev_node to the new one
                end
            end
        end
    end

    output = zeros(input_length,1)';
    curr_idx = 1; %Because of Shouwei, we always end at the zero-state node
    for i = input_length:-1:2
       prev_idx = nodes(curr_idx, i).prev_node;
       output(i-1) = ~(mod(curr_idx,2)); %0 input corresponds to a odd index, 1 input corresponds to a even index
       curr_idx = prev_idx; %Go to next node
    end
    
    output = output(1:end-shouwei); %Remove shouwei part
end

function bin = mydec2bin(dec, bit_size)
%The MATLAB dec2bin converts to a character vector. My function converts to
%a numeric array.
    bin = zeros(bit_size,1)';
    for i = 1:bit_size
       dec = dec/2;
       bin(bit_size-(i-1)) = ~(floor(dec)==dec);
       dec = floor(dec);
    end
end

function d = distance(input, expected)
%Calculates the (Euler) distance between the given input and the expected
%value
    d = sum(abs(input-expected));
end