function [ feistel_out ] = Feistel( R, key )
	%% expansion
    %first divide the 32bit data into 8 groups, each group of 4bit, 
    %Then add the previous group and the next group of 1bit data next to the 4bit head and tail, 
	S = zeros(8, 6);
	for k = 1: 8
		S(k, 2: 5) = R(4*(k-1)+1: 4*k);
		if k == 1
			S(1, 1) = R(32);
		else
			S(k, 1) = R(4*(k-1));
		end
		S(k, 6) = R(mod(4*k+1, 32));
    end
    %Then splice each group of 6bit data into 48bit
    %Note: first digit is added to the end of the last group, and the last digit is added to the head of the first group.
	S = reshape(S', 48, 1);
    
	%% key mixing
    %48bit data obtained in the previous step and the current wheel key can be XORed bit by bit.
	key_mixed = xor(S, key);
	key_mixed = reshape(key_mixed, 6, 8);
	key_mixed = key_mixed';

	%% Substitution
	% substitution box (8 matrices values 0-15, each block corresponds to a different 4*16 matrix)
	S_box = {[14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7;...
			  0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8;...
			  4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0;...
			  15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13],...
			 [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10;...
			  3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5;...
			  0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15;...
			  13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9],...
			 [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8;...
			  13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1;...
			  13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7;...
			  1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12],...
			 [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15;...
			  13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9;...
			  10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4;...
			  3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14],...
			 [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9;...
			  14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6;...
			  4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14;...
			  11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3],...
			 [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11;...
			  10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8;...
			  9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6;...
			  4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13],...
			 [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1;...
			  13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6;...
			  1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2;...
			  6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12],...
			 [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7;...
			  1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2;...
			  7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8;...
			  2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11]};
%Divide the 48-bit data obtained by the XOR into 8 6-bit blocks, 
%and use the 6-bit data calculation of each block to obtain a 4-bit output.
	sub_S = zeros(8, 4);
	for k = 1: 8
		row = 2*key_mixed(k, 1) + key_mixed(k, 6) + 1;
		col = 8*key_mixed(k, 2) + 4*key_mixed(k, 3) + 2*key_mixed(k, 4) + key_mixed(k, 5) + 1;
		d = S_box{k}(row, col);
		for p = 4: -1: 1
			sub_S(k, p) = mod(d, 2);
			d = floor(d/2);
		end
	end
	sub_S = reshape(sub_S', 1, 32);

	%% Permutation
	P = [16, 7, 20, 21,...
		 29, 12, 28, 17,...
		 1, 15, 23, 26,...
		 5, 18, 31, 10,...
		 2, 8, 24, 14,...
		 32, 27, 3, 9,...
		 19, 13, 30, 6,...
		 22, 11, 4, 25];
	feistel_out = zeros(1, 32);
    %each 4bit block obtained in the previous step is scattered into 4 different blocks
	for k = 1: 32
		feistel_out(k) = sub_S(P(k));
    end
    %finally 32bit data is obtained as the output.
	feistel_out = feistel_out';

end

