/// A flash loan that works for any Coin type
module lesson9::flash_lender {
    use sui::object::{UID, Self};
    use sui::tx_context::{TxContext,Self};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Supply, Balance};
    use sui::sui::SUI;
    use sui::math;

    const ErrorZero: u64 = 0;

    struct LSP<phantom P, phantom T> has drop {}

    struct FlashLender<phantom P, phantom T> has key {
        id: UID,
        sui: Balance<SUI>,
        to_lend: Balance<T>,
        lsp_supply: Supply<LSP<P,T>>,
        fee: u64,
    }

    // === Creating a flash lender ===

    fun init(_ctx: &mut sui::tx_context::TxContext) {}

    public fun new<P,T>(to_lend: Coin<T>, sui:Coin<SUI>, fee: u64, ctx: &mut TxContext): Coin<LSP<P,T>> {
        let sui_amount = coin::value(&sui);
        let to_lend_amount = coin::value(&to_lend);

        assert!(sui_amount > 0 && to_lend_amount > 0, ErrorZero);

        let share = math::sqrt(sui_amount) * math::sqrt(to_lend_amount);
        let lsp_supply = balance::create_supply(LSP<P,T>{});
        let lsp = balance::increase_supply(&mut lsp_supply, share);
        let flashlender = FlashLender{
            id: object::new(ctx),
            sui: coin::into_balance(sui),
            to_lend: coin::into_balance(to_lend),
            lsp_supply,
            fee
        };
        transfer::share_object(flashlender);
        coin::from_balance(lsp, ctx)
    }


    public fun loan<P,T>(pool: &mut FlashLender<P,T>, to_lend: Coin<T>, amount: u64, ctx: &mut TxContext): Coin<SUI>{

        let to_lend_balance = coin::into_balance(to_lend);
        let (sui_amount, to_lend_amount, _) = get_pool_amount(pool);

        assert!(sui_amount > 0 && to_lend_amount > 0, ErrorZero);
        let transfer_token = get_input_price(balance::value(&to_lend_balance), 100);

        balance::join(&mut pool.to_lend, to_lend_balance);
        coin::take(&mut pool.sui, transfer_token, ctx);
    }

    entry fun wrap<P,T>(pool: FlashLender<P,T>, to_lend: Coin<T>, ctx: &mut TxContext){
        assert!(coin::value(&to_lend) > 0,ErrorZero);
        transfer::public_transfer(loan(pool, to_lend, ctx)), tx_context::sender(ctx);
    }

    public fun get_pool_amount<P,T>(pool: FlashLender<P,T>) :(u64, u64, u64) {
        (
            balance::value(&pool.sui),
            balance::value(&pool.to_lend),
            balance::supply_value(&pool.lsp_supply)
        )
    }

    public fun get_input_price(input_amount: u64, fee: u64): u64 {
        let number: u64 = 12;
        number
    }

}
