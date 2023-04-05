module perpsea::oracle {
    use std::type_name::TypeName;
    use std::vector;
    use sui::table::Table;
    use sui::tx_context::TxContext;
    use sui::table;
    use sui::transfer;
    use sui::object::{UID, Self};
    use sui::tx_context;
    use std::type_name;

    // errors
    const ETOKEN_NOT_FOUND: u64 = 0;
    const EUNAUTHORIZED: u64 = 1;

    struct Oracle has key {
        id: UID,
        admin: address,
        prices: Table<TypeName, u256>,
    }

    fun init(
        ctx: &mut TxContext,
    ) {
        let oracle = Oracle {
            id: object::new(ctx),
            prices: table::new(ctx),
            admin: tx_context::sender(ctx),
        };
        transfer::share_object(oracle);
    }

    #[test_only]
    public fun init_for_testing(
        ctx: &mut TxContext,
    ) {
        init(ctx);
    }

    public fun get_price(
        oracle: &Oracle,
        token: &TypeName,
        _max: bool,
    ): u256 {
        assert!(table::contains(&oracle.prices, *token), ETOKEN_NOT_FOUND);
        *table::borrow(&oracle.prices, *token)
    }

    public fun get_multiple_prices(
        oracle: &Oracle,
        tokens: vector<TypeName>,
        max: bool,
    ): vector<u256> {
        let prices = vector::empty<u256>();
        let i = 0;
        let len = vector::length(&tokens);
        while (i < len) {
            let token = vector::borrow(&tokens, i);
            let price = get_price(oracle, token, max);
            vector::push_back(&mut prices, price);
            i = i + 1;
        };
        prices
    }

    public entry fun set_price<T>(
        oracle: &mut Oracle,
        price: u256,
        ctx: &mut TxContext,
    ) {
        assert!(tx_context::sender(ctx) == oracle.admin, EUNAUTHORIZED);
        let token = type_name::get<T>();
        if(table::contains(&oracle.prices, token)) {
            let prev_price = table::borrow_mut(&mut oracle.prices, token);
            *prev_price = price;
        } else {
            table::add(&mut oracle.prices, token, price);
        }
    }
}
