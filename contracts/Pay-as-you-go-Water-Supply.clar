(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-METER-NOT-ACTIVE (err u105))
(define-constant ERR-UNAUTHORIZED (err u106))
(define-constant ERR-INVALID-RATE (err u107))
(define-constant ERR-INSUFFICIENT-FUNDS (err u108))

(define-data-var base-rate uint u50)
(define-data-var service-fee uint u10)
(define-data-var contract-balance uint u0)
(define-data-var total-meters uint u0)

(define-map water-meters
    { meter-id: uint }
    {
        owner: principal,
        balance: uint,
        usage: uint,
        last-reading: uint,
        rate-per-liter: uint,
        active: bool,
        created-at: uint,
    }
)

(define-map user-balances
    { user: principal }
    { balance: uint }
)

(define-map meter-owners
    { owner: principal }
    { meter-ids: (list 10 uint) }
)

(define-map usage-history
    {
        meter-id: uint,
        block-num: uint,
    }
    {
        usage-amount: uint,
        cost: uint,
        timestamp: uint,
    }
)

(define-map payment-history
    {
        user: principal,
        payment-id: uint,
    }
    {
        amount: uint,
        timestamp: uint,
        meter-id: uint,
    }
)

(define-data-var next-payment-id uint u1)

(define-read-only (get-contract-owner)
    CONTRACT-OWNER
)

(define-read-only (get-base-rate)
    (var-get base-rate)
)

(define-read-only (get-service-fee)
    (var-get service-fee)
)

(define-read-only (get-contract-balance)
    (var-get contract-balance)
)

(define-read-only (get-total-meters)
    (var-get total-meters)
)

(define-read-only (get-water-meter (meter-id uint))
    (map-get? water-meters { meter-id: meter-id })
)

(define-read-only (get-user-balance (user principal))
    (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-user-meters (owner principal))
    (default-to (list) (get meter-ids (map-get? meter-owners { owner: owner })))
)

(define-read-only (get-usage-history
        (meter-id uint)
        (block-num uint)
    )
    (map-get? usage-history {
        meter-id: meter-id,
        block-num: block-num,
    })
)

(define-read-only (get-payment-history
        (user principal)
        (payment-id uint)
    )
    (map-get? payment-history {
        user: user,
        payment-id: payment-id,
    })
)

(define-read-only (calculate-usage-cost
        (usage-amount uint)
        (rate-per-liter uint)
    )
    (+ (* usage-amount rate-per-liter) (var-get service-fee))
)

(define-read-only (is-meter-owner
        (meter-id uint)
        (user principal)
    )
    (match (get-water-meter meter-id)
        meter (is-eq (get owner meter) user)
        false
    )
)

(define-public (set-base-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (asserts! (> new-rate u0) ERR-INVALID-RATE)
        (ok (var-set base-rate new-rate))
    )
)

(define-public (set-service-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (ok (var-set service-fee new-fee))
    )
)

(define-public (register-meter (rate-per-liter uint))
    (let (
            (meter-id (+ (var-get total-meters) u1))
            (current-block u0)
            (user-meters (get-user-meters tx-sender))
        )
        (asserts! (> rate-per-liter u0) ERR-INVALID-RATE)
        (asserts! (< (len user-meters) u10) ERR-INVALID-AMOUNT)
        (map-set water-meters { meter-id: meter-id } {
            owner: tx-sender,
            balance: u0,
            usage: u0,
            last-reading: u0,
            rate-per-liter: rate-per-liter,
            active: true,
            created-at: current-block,
        })
        (map-set meter-owners { owner: tx-sender } { meter-ids: (unwrap! (as-max-len? (append user-meters meter-id) u10)
            ERR-INVALID-AMOUNT
        ) }
        )
        (var-set total-meters meter-id)
        (ok meter-id)
    )
)

(define-public (add-balance (amount uint))
    (let ((current-balance (get-user-balance tx-sender)))
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set user-balances { user: tx-sender } { balance: (+ current-balance amount) })
        (var-set contract-balance (+ (var-get contract-balance) amount))
        (let ((payment-id (var-get next-payment-id)))
            (map-set payment-history {
                user: tx-sender,
                payment-id: payment-id,
            } {
                amount: amount,
                timestamp: u0,
                meter-id: u0,
            })
            (var-set next-payment-id (+ payment-id u1))
            (ok amount)
        )
    )
)

(define-public (record-usage
        (meter-id uint)
        (usage-amount uint)
    )
    (let (
            (meter-data (unwrap! (get-water-meter meter-id) ERR-NOT-FOUND))
            (user-balance (get-user-balance (get owner meter-data)))
            (usage-cost (calculate-usage-cost usage-amount (get rate-per-liter meter-data)))
            (current-block u0)
        )
        (asserts! (get active meter-data) ERR-METER-NOT-ACTIVE)
        (asserts! (is-meter-owner meter-id tx-sender) ERR-UNAUTHORIZED)
        (asserts! (> usage-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= user-balance usage-cost) ERR-INSUFFICIENT-BALANCE)
        (map-set user-balances { user: (get owner meter-data) } { balance: (- user-balance usage-cost) })
        (map-set water-meters { meter-id: meter-id } {
            owner: (get owner meter-data),
            balance: (get balance meter-data),
            usage: (+ (get usage meter-data) usage-amount),
            last-reading: usage-amount,
            rate-per-liter: (get rate-per-liter meter-data),
            active: (get active meter-data),
            created-at: (get created-at meter-data),
        })
        (map-set usage-history {
            meter-id: meter-id,
            block-num: current-block,
        } {
            usage-amount: usage-amount,
            cost: usage-cost,
            timestamp: current-block,
        })
        (ok usage-cost)
    )
)

(define-public (deactivate-meter (meter-id uint))
    (let ((meter-data (unwrap! (get-water-meter meter-id) ERR-NOT-FOUND)))
        (asserts! (is-meter-owner meter-id tx-sender) ERR-UNAUTHORIZED)
        (map-set water-meters { meter-id: meter-id } {
            owner: (get owner meter-data),
            balance: (get balance meter-data),
            usage: (get usage meter-data),
            last-reading: (get last-reading meter-data),
            rate-per-liter: (get rate-per-liter meter-data),
            active: false,
            created-at: (get created-at meter-data),
        })
        (ok true)
    )
)

(define-public (activate-meter (meter-id uint))
    (let ((meter-data (unwrap! (get-water-meter meter-id) ERR-NOT-FOUND)))
        (asserts! (is-meter-owner meter-id tx-sender) ERR-UNAUTHORIZED)
        (map-set water-meters { meter-id: meter-id } {
            owner: (get owner meter-data),
            balance: (get balance meter-data),
            usage: (get usage meter-data),
            last-reading: (get last-reading meter-data),
            rate-per-liter: (get rate-per-liter meter-data),
            active: true,
            created-at: (get created-at meter-data),
        })
        (ok true)
    )
)

(define-public (update-meter-rate
        (meter-id uint)
        (new-rate uint)
    )
    (let ((meter-data (unwrap! (get-water-meter meter-id) ERR-NOT-FOUND)))
        (asserts! (is-meter-owner meter-id tx-sender) ERR-UNAUTHORIZED)
        (asserts! (> new-rate u0) ERR-INVALID-RATE)
        (map-set water-meters { meter-id: meter-id } {
            owner: (get owner meter-data),
            balance: (get balance meter-data),
            usage: (get usage meter-data),
            last-reading: (get last-reading meter-data),
            rate-per-liter: new-rate,
            active: (get active meter-data),
            created-at: (get created-at meter-data),
        })
        (ok new-rate)
    )
)

(define-public (withdraw-balance (amount uint))
    (let ((user-balance (get-user-balance tx-sender)))
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
        (map-set user-balances { user: tx-sender } { balance: (- user-balance amount) })
        (var-set contract-balance (- (var-get contract-balance) amount))
        (as-contract (stx-transfer? amount tx-sender tx-sender))
    )
)

(define-public (emergency-withdraw)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender CONTRACT-OWNER))
    )
)

(define-map usage-delegations
    {
        meter-id: uint,
        delegate: principal,
    }
    {
        remaining: uint,
        enabled: bool,
    }
)

(define-read-only (get-usage-delegation
        (meter-id uint)
        (delegate principal)
    )
    (map-get? usage-delegations {
        meter-id: meter-id,
        delegate: delegate,
    })
)

(define-public (set-usage-delegation
        (meter-id uint)
        (delegate principal)
        (allowance uint)
    )
    (let ((meter-data (unwrap! (get-water-meter meter-id) ERR-NOT-FOUND)))
        (asserts! (is-meter-owner meter-id tx-sender) ERR-UNAUTHORIZED)
        (asserts! (> allowance u0) ERR-INVALID-AMOUNT)
        (map-set usage-delegations {
            meter-id: meter-id,
            delegate: delegate,
        } {
            remaining: allowance,
            enabled: true,
        })
        (ok true)
    )
)

(define-public (revoke-usage-delegation
        (meter-id uint)
        (delegate principal)
    )
    (let ((meter-data (unwrap! (get-water-meter meter-id) ERR-NOT-FOUND)))
        (asserts! (is-meter-owner meter-id tx-sender) ERR-UNAUTHORIZED)
        (map-set usage-delegations {
            meter-id: meter-id,
            delegate: delegate,
        } {
            remaining: u0,
            enabled: false,
        })
        (ok true)
    )
)

(define-public (record-usage-delegate
        (meter-id uint)
        (usage-amount uint)
    )
    (let (
            (meter-data (unwrap! (get-water-meter meter-id) ERR-NOT-FOUND))
            (delegation (unwrap!
                (map-get? usage-delegations {
                    meter-id: meter-id,
                    delegate: tx-sender,
                })
                ERR-UNAUTHORIZED
            ))
            (current-block u0)
            (usage-cost (calculate-usage-cost usage-amount (get rate-per-liter meter-data)))
            (owner (get owner meter-data))
            (user-balance (get-user-balance owner))
            (remaining (get remaining delegation))
        )
        (asserts! (get active meter-data) ERR-METER-NOT-ACTIVE)
        (asserts! (> usage-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (get enabled delegation) ERR-UNAUTHORIZED)
        (asserts! (>= user-balance usage-cost) ERR-INSUFFICIENT-BALANCE)
        (asserts! (>= remaining usage-cost) ERR-INSUFFICIENT-FUNDS)
        (map-set user-balances { user: owner } { balance: (- user-balance usage-cost) })
        (map-set water-meters { meter-id: meter-id } {
            owner: owner,
            balance: (get balance meter-data),
            usage: (+ (get usage meter-data) usage-amount),
            last-reading: usage-amount,
            rate-per-liter: (get rate-per-liter meter-data),
            active: (get active meter-data),
            created-at: (get created-at meter-data),
        })
        (map-set usage-delegations {
            meter-id: meter-id,
            delegate: tx-sender,
        } {
            remaining: (- remaining usage-cost),
            enabled: true,
        })
        (map-set usage-history {
            meter-id: meter-id,
            block-num: current-block,
        } {
            usage-amount: usage-amount,
            cost: usage-cost,
            timestamp: current-block,
        })
        (ok usage-cost)
    )
)
