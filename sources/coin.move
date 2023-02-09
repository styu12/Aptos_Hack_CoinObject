module coin_objects::coin {
    use std::string::{Self, String};
    // use std::option::{Self, Option};
    use std::vector;
    use std::signer;
    use std::bcs;

    // use aptos_framework::optional_aggregator::{Self, OptionalAggregator};
    use aptos_framework::object::{Self, CreatorRef, ObjectId};
    // no coin resource exists
    const ENO_COINS:u64 = 1;

    const SELLER:address = @0x93b2948a9e627378688f56f3b922e6f70874e7a7687fdad14407e8c137185cf9;

    struct MirnyCoin {}

    public entry fun test_transfer(account: &signer) acquires Coins, Coin {
        let seller_coins_object_id = mint_to<MirnyCoin>(
            account,
            SELLER,
            string::utf8(b"Mirny Coin"),
            string::utf8(b"MIR"),
            0
        ); 
        std::debug::print(&string::utf8(b"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"));
        std::debug::print(&string::utf8(b"[Seller Coins Object Address]"));
        std::debug::print(&object::object_id_address(&seller_coins_object_id));
        let seller_coins_obj = borrow_global<Coins<MirnyCoin>>(object::object_id_address(&seller_coins_object_id));
        std::debug::print(&string::utf8(b"!!Seller Coins Object Balance!!"));
        std::debug::print(&seller_coins_obj.balance);
        std::debug::print(&string::utf8(b" "));

        let buyer_coins_object_id = mint<MirnyCoin>(
            account,
            string::utf8(b"Mirny Coin"),
            string::utf8(b"MIR"),
            400
        );
        std::debug::print(&string::utf8(b"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"));
        std::debug::print(&string::utf8(b"[Buyer Coins Object Address]"));
        std::debug::print(&object::object_id_address(&buyer_coins_object_id));
        let buyer_coins_obj = borrow_global<Coins<MirnyCoin>>(object::object_id_address(&buyer_coins_object_id));
        std::debug::print(&string::utf8(b"!!Buyer Coins Object Balance!!"));
        std::debug::print(&buyer_coins_obj.balance);
        std::debug::print(&string::utf8(b" "));
        

        let coin_object = withdraw<MirnyCoin>(account, 100, buyer_coins_object_id);
        deposit(seller_coins_object_id, coin_object);
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Coins<phantom T> has key, store {
        name: String,
        symbol: String,
        balance: u64
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Coin<phantom T> has key, store, drop, copy {
        name: String,
        symbol: String,
        value: u64
    }

    public fun mint<T>(
        creator: &signer,
        name: String,
        symbol: String,
        amount: u64
    ): ObjectId {
           // make Coins<T> Object
            let my_coins_seed = create_coins_id_seed(&signer::address_of(creator), &name, &symbol);
            let my_coins_creator_ref = object::create_named_object(creator, my_coins_seed);
            let my_coins_object_signer = object::generate_signer(&my_coins_creator_ref);
            let my_coins_object_id = object::address_to_object_id(signer::address_of(&my_coins_object_signer));

            let my_coins = Coins<T> {
                name,
                symbol,
                balance: amount 
            };
            move_to(&my_coins_object_signer, my_coins);
            my_coins_object_id
            // object::address_to_object_id(signer::address_of(&my_coins_object_signer))
    }

    public fun mint_to<T>(
        creator: &signer,
        to: address,
        name: String,
        symbol: String,
        amount: u64
    ): ObjectId {
           // make Coins<T> Object
            let coins_seed = create_coins_id_seed(&to, &name, &symbol);
            let coins_creator_ref = object::create_named_object(creator, coins_seed);
            let coins_object_signer = object::generate_signer(&coins_creator_ref);
            let coins_object_id = object::address_to_object_id(signer::address_of(&coins_object_signer));

            let coins = Coins<T> {
                name,
                symbol,
                balance: amount
            };

            move_to(&coins_object_signer, coins);
            object::transfer(
                creator,
                coins_object_id,
                @0x08faf857756cb0ec0d17cdd6990d3d23930a0e30c03ddaa2b39dbcc932f5656e
            );
            coins_object_id
    }

    public fun withdraw<T>(
        account: &signer, 
        amount: u64,
        coins: ObjectId
    ): Coin<T> acquires Coins, Coin {
        assert!(exists<Coins<T>>(object::object_id_address(&coins)), ENO_COINS);
        let coins_obj = borrow_global_mut<Coins<T>>(object::object_id_address(&coins));
        coins_obj.balance = coins_obj.balance - amount;

        let coin_creator_ref = initialize_coin<T>(
            account,
            coins_obj.name,
            coins_obj.symbol,
            amount,
        );

        let coin_object_signer = object::generate_signer(&coin_creator_ref);
        let coin_object_id = object::address_to_object_id(signer::address_of(&coin_object_signer));
        let coin_obj = move_from<Coin<T>>(object::object_id_address(&coin_object_id));
        std::debug::print(&string::utf8(b"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"));
        std::debug::print(&string::utf8(b"Coin Object Created!!! The value amount is "));
        std::debug::print(&coin_obj.value);
        std::debug::print(&string::utf8(b"[Coin Object Address]"));
        std::debug::print(&object::object_id_address(&coin_object_id));
        std::debug::print(&string::utf8(b" "));
        coin_obj
    }
    

    public fun deposit<T>(
        to: ObjectId, 
        coin_to_deposit: Coin<T>
    )  acquires Coins {
        assert!(exists<Coins<T>>(object::object_id_address(&to)), ENO_COINS);
        let dst_coins_object = borrow_global_mut<Coins<T>>(object::object_id_address(&to));
        dst_coins_object.balance = dst_coins_object.balance + coin_to_deposit.value;
    }

    fun initialize_coin<T>(
        creator: &signer,
        name: String,
        symbol: String,
        amount: u64
    ): CreatorRef {
        // make coin object
        let coin_seed = create_coin_id_seed(&name, &symbol);
        let coin_creator_ref = object::create_named_object(creator, coin_seed);
        let coin_object_signer = object::generate_signer(&coin_creator_ref);

        let coin = Coin<T> {
            name,
            symbol,
            value: amount
        };

        move_to(&coin_object_signer, coin);
        coin_creator_ref
    }

    fun create_coin_id_seed(name: &String, symbol: &String): vector<u8> {
        let seed = *string::bytes(name);
        vector::append(&mut seed, b"::");
        vector::append(&mut seed, *string::bytes(symbol));
        seed
    }

    public fun create_coins_id_seed(creator_address: &address, name: &String, symbol: &String): vector<u8> {
        let seed = bcs::to_bytes(creator_address);
        vector::append(&mut seed, b"::");
        vector::append(&mut seed, *string::bytes(name));
        vector::append(&mut seed, b"::");
        vector::append(&mut seed, *string::bytes(symbol));
        seed
    }
}