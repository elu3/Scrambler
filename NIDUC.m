%GENEROWANIE
rgb = imread('Yosemite.jpg');
vector = double(rgb(2,1:500,2));

factor = 3/550;
sequence01 = vector*factor;
sequence1 = round(sequence01);

%liczenie zer przed scramblingiem
zeros_tab=zeros(1, 100);
counter = 0;
for i=1:size(sequence1,2);
    if sequence1(i) == 0
        counter=counter+1;
    else if counter > 0
        zeros_tab(counter) = zeros_tab(counter)+1;
        counter = 0;
        end
    end
end

%liczenie jedynek przed scramblingiem
ones_tab=zeros(1, 100);
counter = 0;
for i=1:size(sequence1,2);
    if sequence1(i) == 1
        counter=counter+1;
    else if counter > 0
        ones_tab(counter) = ones_tab(counter)+1;
        counter = 0;
        end
    end
end

figure(1);
subplot(2,1,1);
bar(zeros_tab);
title('zera przed scramblingiem');

figure(2);
subplot(2,1,1);
bar(ones_tab);
title('jedynki przed scramblingiem');

% scrambler DVB
scrambler_input=sequence1; 
s=20255; %klucz
rand_data=zeros(size(scrambler_input));
for i=1:size(scrambler_input,2);
    msb=bitxor(bitget(s,1),bitget(s,2)); % xor dwóch pierwszych (najm?odszych) bitów
    s=bitshift(s,-1); % przeuniecie biów o jeden w prawo
    s=bitset(s,15,msb); % ustawienie pierwzego (najstarszego) bitu
    t=bitxor(scrambler_input(i),msb); % xor wej?cia z msb
    rand_data(i)=t; % ustawienie bitu w wyniku
end
scrambler_out=rand_data; % wynik

% liczenie zer po scramblingu
zeros_tab2=zeros(1, 10);
counter = 0;
for i=1:size(scrambler_out,2);
    if scrambler_out(i) == 0
        counter=counter+1;
    else if counter > 0
        zeros_tab2(counter) = zeros_tab2(counter)+1;
        counter = 0;
        end
    end
end

%liczenie jedynek po scramblingu
ones_tab2=zeros(1, 10);
counter = 0;
for i=1:size(scrambler_out,2);
    if scrambler_out(i) == 1
        counter=counter+1;
    else if counter > 0
        ones_tab2(counter) = ones_tab2(counter)+1;
        counter = 0;
        end
    end
end

figure(1);
subplot(2, 1, 2);
bar(zeros_tab2);
title('zera po scramblingu');

figure(2);
subplot(2,1,2);
bar(ones_tab2);
title('jedynki po scramblingu');

% descrambler DVB
s=20255; %klucz
descrambler_in=zeros(size(scrambler_out));
for i=1:size(scrambler_out,2);
    msb=bitxor(bitget(s,1),bitget(s,2)); % xor dwóch pierwszych (najmlodszych) bitów
    s=bitshift(s,-1); % przesuniecie bitow o jeden w prawo
    s=bitset(s,15,msb); % ustawienie pierwszego(najstarszego) bitu
    t=bitxor(scrambler_out(i),msb); % xor wej?cia z msb
    descrambler_in(i)=t; % ustawienie bitu w wyniku
end
descrambler_out=descrambler_in; %wynik

%ZAPIS DO PLIKU
fileID = fopen('generator.txt','w');
fprintf(fileID, '%d \r\n', sequence1);
fclose(fileID);

fileID = fopen('scrambler.txt','w');
fprintf(fileID, '%d \r\n', scrambler_out);
fclose(fileID);

fileID = fopen('descrambler.txt','w');
fprintf(fileID, '%d \r\n', descrambler_out);
fclose(fileID);

%liczba zer powodujacych przerwanei transmisji
zeroes_count = 5;
%wspolczynnik odleglosci pomiedzy sekwencjami synchronizacyjnymi
%przy poprawnym przeslaniu bitow
%tj. ilosc dobrze przelanych bitow po ktorych nastepuje sekwencja
%synchronizacyjna
k = 20;

%fprintf('k = %d \n', k);

%wektor bitow po transmisji dla wejscia scramblera
scrambler_in_syn = 1:0;
%liczba zlych bitow podczas transmisji
scrambler_in_bad_bits = 0;
%liczba dobrych bitow podczas transmisji
scrambler_in_good_bits = 0;
%licznik dla wektora transmisji
counter = 0;
%licznik nastepujacych po sobie zer
counterzeroes = 0;
%zlicza kolejne dobrze przeslane bity
%wykorzystywany do nadania bitow synchronizacji 
%po odpowiedniej liczbie bitow
standard_syn_counter = 0;
%liczba przerwan transmisji
syn_error = 0;
%inkrementuje wektor scrambler_input omijajac w razie przerwania
%odpowiednia liczbe bitow
increment = 1;
%przechodzi po kolejnych pozycjach scrambler_input
i = 1;

%SYNCHRONIZACJA dla wejscia scramblera
while i <= size(scrambler_input,2)
    if (increment > 1 && i ~= size(scrambler_input,2))
        scrambler_in_syn(counter) = 1;
        scrambler_in_syn(counter+1) = 1;
        scrambler_in_syn(counter+2) = 0;
        scrambler_in_syn(counter+3) = 0;
        scrambler_in_syn(counter+4) = 1;
        counter = counter + 5;
        scrambler_in_bad_bits = scrambler_in_bad_bits + 5;
    end
    increment = 1;
    counter = counter + 1;
    standard_syn_counter = standard_syn_counter + 1;
    
    if (scrambler_input(i) == 0 && mod(i,k) ~= 0) 
        counterzeroes = counterzeroes + 1;
        if (counterzeroes == zeroes_count)
            increment = k - mod(i,k)+1;
            syn_error = syn_error + 1;
            counterzeroes = 0;
            scrambler_in_bad_bits = scrambler_in_bad_bits + increment - 1;
            standard_syn_counter = 0;
        end
    else if (scrambler_input(i) == 1) 
        counterzeroes = 0;
        end
    end
    
    scrambler_in_syn(counter) = scrambler_input(i);
    
    if (mod(standard_syn_counter,k) == 0 && standard_syn_counter ~= 0 && i ~= size(scrambler_input,2))
        scrambler_in_syn(counter+1) = 1;
        scrambler_in_syn(counter+2) = 1;
        scrambler_in_syn(counter+3) = 0;
        scrambler_in_syn(counter+4) = 0;
        scrambler_in_syn(counter+5) = 1;
        counter = counter + 5;
        scrambler_in_bad_bits = scrambler_in_bad_bits + 5;
    end
    
    i = i + increment;
    scrambler_in_good_bits = scrambler_in_good_bits + 1;
end

fprintf('Liczba zerwan transmisji bez scramblingu = %d \n', syn_error);


scrambler_out_syn = 1:0;
scrambler_out_bad_bits = 0;
scrambler_out_good_bits = 0;
counter = 0;
counterzeroes = 0;
standard_syn_counter = 0;
syn_error = 0;
increment = 1;
i = 1;

%SYNCHRONIZACJA dla wyjscia scramblera
while i <= size(scrambler_out,2)
    if (increment > 1 && i ~= size(scrambler_out,2))
        scrambler_out_syn(counter) = 1;
        scrambler_out_syn(counter+1) = 1;
        scrambler_out_syn(counter+2) = 0;
        scrambler_out_syn(counter+3) = 0;
        scrambler_out_syn(counter+4) = 1;
        counter = counter + 5;
        scrambler_out_bad_bits = scrambler_out_bad_bits + 5;
    end
    increment = 1;
    counter = counter + 1;
    standard_syn_counter = standard_syn_counter + 1;
    
    if (scrambler_out(i) == 0 && mod(i,k) ~= 0) 
        counterzeroes = counterzeroes + 1;
        if (counterzeroes == zeroes_count)
            increment = k - mod(i,k)+1;
            syn_error = syn_error + 1;
            counterzeroes = 0;
            scrambler_out_bad_bits = scrambler_out_bad_bits + increment - 1;
            standard_syn_counter = 0;
        end
    else if (scrambler_out(i) == 1) 
        counterzeroes = 0;
        end
    end
    
    %fprintf('counter = %d  i = %d \n',counter,i);
    scrambler_out_syn(counter) = scrambler_out(i);
    
    if (mod(standard_syn_counter,k) == 0 && standard_syn_counter ~= 0 && i ~= size(scrambler_out,2))
        scrambler_out_syn(counter+1) = 1;
        scrambler_out_syn(counter+2) = 1;
        scrambler_out_syn(counter+3) = 0;
        scrambler_out_syn(counter+4) = 0;
        scrambler_out_syn(counter+5) = 1;
        counter = counter + 5;
        scrambler_out_bad_bits = scrambler_out_bad_bits + 5;
    end
   % if (increment ~= 1)
   %     fprintf('i = %d  increment = %d \n',i,increment);
   % end 
    i = i + increment;
    scrambler_out_good_bits = scrambler_out_good_bits + 1;
end

fprintf('Liczba zerwan transmisji ze scramblingiem = %d \n', syn_error);

a_factor_in = (scrambler_in_good_bits) / (scrambler_in_good_bits + scrambler_in_bad_bits);
a_factor_out = (scrambler_out_good_bits) / (scrambler_out_good_bits + scrambler_out_bad_bits);

%fprintf('\n');
%fprintf('Wspolczynnika A bez scramblingu = %f \n', a_factor_in);
%fprintf('Wspolczynnika A ze scramblingiem = %f \n', a_factor_out);
%fprintf('k = %d\n', k);
%fprintf('A = %f\n', a_factor_in);
%fprintf('A = %f\n', a_factor_out);

best_k_in = [0 , 0];
best_k_out = [0 , 0];

fileID = fopen('k.txt','r');
formatSpec = '%f\r\n';
j = 1;
k_matrix = fscanf(fileID,formatSpec,500);
k_vector = 1:500;
while j <= 500
    k_vector(j) = k_matrix(j:j);
    j = j+1;
end
fclose(fileID);

fileID = fopen('A(k)_in.txt','r');
formatSpec = '%f\r\n';
j = 1;
akin_matrix = fscanf(fileID,formatSpec,500);
akin_vector = 1:500;
while j <= 500
    akin_vector(j) = akin_matrix(j:j);
    if (akin_vector(j) > best_k_in(1))
        best_k_in(1) = akin_vector(j);
        best_k_in(2) = j;
    end
    j = j+1;
end
fclose(fileID);

fileID = fopen('A(k)_out.txt','r');
formatSpec = '%f\r\n';
j = 1;
akout_matrix = fscanf(fileID,formatSpec,500);
akout_vector = 1:500;
while j <= 500
    akout_vector(j) = akout_matrix(j:j);
    if (akout_vector(j) > best_k_out(1))
        best_k_out(1) = akout_vector(j);
        best_k_out(2) = j;
    end
    j = j+1;
end
fclose(fileID);

figure(3);
subplot(2,1,1);
plot(k_vector, akin_vector);
subplot(2,1,2);
plot(k_vector, akout_vector);

fprintf('\n');
fprintf('Najlepsze wartosc wspolczynnika k dla wejscia scramblera wynosi %d.\n', best_k_in(2));
fprintf('Najlepsze wartosc wspolczynnika k dla wyjscia scramblera wynosi %d.\n', best_k_out(2));