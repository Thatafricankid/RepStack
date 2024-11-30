;; RepStack - Enhanced DAO Reputation System
;; A comprehensive reputation tracking system for DAOs on Stacks blockchain

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-score (err u103))
(define-constant err-invalid-parameter (err u104))
(define-constant err-invalid-proposal-id (err u111))
(define-constant err-invalid-action (err u112))
(define-constant max-proposal-id u1000000)
(define-constant max-weight u1000)

;; Enhanced Data Maps
(define-map user-scores 
    principal 
    {
        reputation-score: uint,
        proposal-count: uint,
        vote-count: uint,
        last-action: uint,
        contribution-count: uint,
        successful-proposals: uint,
        vote-participation-rate: uint,
        community-kudos: uint
    }
)

(define-map contribution-weights
    {action: (string-ascii 24)}
    {
        base-weight: uint,
        multiplier: uint,
        minimum-threshold: uint
    }
)

(define-map proposal-records
    uint
    {
        proposer: principal,
        status: (string-ascii 12),
        vote-count: uint,
        created-at: uint
    }
)

;; Initialize contribution weights with enhanced parameters
(map-set contribution-weights 
    {action: "proposal"} 
    {
        base-weight: u10,
        multiplier: u2,
        minimum-threshold: u5
    }
)
(map-set contribution-weights 
    {action: "vote"} 
    {
        base-weight: u5,
        multiplier: u1,
        minimum-threshold: u10
    }
)
(map-set contribution-weights 
    {action: "contribution"} 
    {
        base-weight: u15,
        multiplier: u3,
        minimum-threshold: u3
    }
)

;; Input Validation Functions
(define-private (is-valid-proposal-id (proposal-id uint))
    (and 
        (> proposal-id u0)
        (<= proposal-id max-proposal-id)
    )
)

(define-private (is-valid-weight (weight uint))
    (<= weight max-weight)
)

(define-private (is-valid-action (action (string-ascii 24)))
    (or 
        (is-eq action "proposal")
        (is-eq action "vote")
        (is-eq action "contribution")
    )
)

;; Enhanced Public Functions

(define-public (initialize-user)
    (begin
        (asserts! (is-none (get-user-score tx-sender)) (err u105))
        (ok (map-set user-scores tx-sender {
            reputation-score: u0,
            proposal-count: u0,
            vote-count: u0,
            last-action: block-height,
            contribution-count: u0,
            successful-proposals: u0,
            vote-participation-rate: u0,
            community-kudos: u0
        }))
    )
)

(define-public (record-proposal (proposal-id uint))
    (begin
        (asserts! (is-valid-proposal-id proposal-id) err-invalid-proposal-id)
        (let (
            (user-data (unwrap! (get-user-score tx-sender) (err u106)))
            (weight-data (unwrap! (map-get? contribution-weights {action: "proposal"}) (err u107)))
            (new-score (calculate-weighted-score 
                (get base-weight weight-data) 
                (get multiplier weight-data) 
                (get proposal-count user-data)
            ))
        )
        (begin
            (asserts! (is-none (map-get? proposal-records proposal-id)) err-invalid-parameter)
            (map-set proposal-records proposal-id {
                proposer: tx-sender,
                status: "active",
                vote-count: u0,
                created-at: block-height
            })
            (ok (map-set user-scores tx-sender (merge user-data {
                reputation-score: (+ (get reputation-score user-data) new-score),
                proposal-count: (+ (get proposal-count user-data) u1),
                last-action: block-height
            })))
        ))
    )
)

(define-public (record-vote (proposal-id uint))
    (begin
        (asserts! (is-valid-proposal-id proposal-id) err-invalid-proposal-id)
        (let (
            (user-data (unwrap! (get-user-score tx-sender) (err u106)))
            (weight-data (unwrap! (map-get? contribution-weights {action: "vote"}) (err u107)))
            (proposal-data (unwrap! (map-get? proposal-records proposal-id) (err u108)))
            (new-score (calculate-weighted-score 
                (get base-weight weight-data) 
                (get multiplier weight-data) 
                (get vote-count user-data)
            ))
            (new-vote-count (+ (get vote-count proposal-data) u1))
        )
        (begin
            (asserts! (is-eq (get status proposal-data) "active") err-invalid-parameter)
            (map-set proposal-records proposal-id 
                (merge proposal-data {vote-count: new-vote-count}))
            (ok (map-set user-scores tx-sender (merge user-data {
                reputation-score: (+ (get reputation-score user-data) new-score),
                vote-count: (+ (get vote-count user-data) u1),
                vote-participation-rate: (calculate-participation-rate 
                    (+ (get vote-count user-data) u1) 
                    (get proposal-count user-data)
                ),
                last-action: block-height
            })))
        ))
    )
)

(define-public (update-proposal-status (proposal-id uint) (new-status (string-ascii 12)))
    (begin
        (asserts! (is-valid-proposal-id proposal-id) err-invalid-proposal-id)
        (let (
            (proposal-data (unwrap! (map-get? proposal-records proposal-id) (err u108)))
            (proposer-data (unwrap! (get-user-score (get proposer proposal-data)) (err u109)))
        )
        (begin
            (asserts! (is-eq tx-sender contract-owner) err-owner-only)
            (asserts! (or (is-eq new-status "successful") (is-eq new-status "failed")) err-invalid-parameter)
            (if (is-eq new-status "successful")
                (map-set user-scores (get proposer proposal-data) 
                    (merge proposer-data {
                        successful-proposals: (+ (get successful-proposals proposer-data) u1),
                        reputation-score: (+ (get reputation-score proposer-data) u50)
                    })
                )
                true
            )
            (ok (map-set proposal-records proposal-id 
                (merge proposal-data {status: new-status})))
        ))
    )
)

(define-public (award-community-kudos (user principal))
    (let (
        (recipient-data (unwrap! (get-user-score user) (err u110)))
    )
    (begin
        (asserts! (not (is-eq tx-sender user)) err-unauthorized)
        (ok (map-set user-scores user (merge recipient-data {
            community-kudos: (+ (get community-kudos recipient-data) u1),
            reputation-score: (+ (get reputation-score recipient-data) u5)
        })))
    ))
)

;; Enhanced Private Functions

(define-private (calculate-weighted-score (base uint) (multiplier uint) (count uint))
    (let (
        (activity-bonus (if (> count u10) u2 u1))
    )
    (* base (* multiplier activity-bonus))
    )
)

(define-private (calculate-participation-rate (votes uint) (total-proposals uint))
    (if (> total-proposals u0)
        (* (/ votes total-proposals) u100)
        u0
    )
)

(define-private (decay-score (original-score uint) (blocks-passed uint))
    (let (
        (decay-factor (/ blocks-passed u1000))
        (minimum-score (/ original-score u10))
        (decayed-score (if (> decay-factor u0)
            (/ original-score decay-factor)
            original-score))
    )
    (if (< decayed-score minimum-score)
        minimum-score
        decayed-score)
    )
)

;; Enhanced Read-only Functions

(define-read-only (get-user-score (user principal))
    (map-get? user-scores user)
)

(define-read-only (get-proposal-data (proposal-id uint))
    (map-get? proposal-records proposal-id)
)

(define-read-only (get-action-weight (action (string-ascii 24)))
    (map-get? contribution-weights {action: action})
)

(define-read-only (get-current-score (user principal))
    (let (
        (user-data (unwrap! (get-user-score user) err-not-found))
        (blocks-since-last-action (- block-height (get last-action user-data)))
        (base-score (get reputation-score user-data))
        (participation-bonus (if (> (get vote-participation-rate user-data) u75) u50 u0))
        (success-bonus (* (get successful-proposals user-data) u25))
    )
    (ok (+ 
        (+ (decay-score base-score blocks-since-last-action) participation-bonus)
        success-bonus
    )))
)

;; Administrative Functions

(define-public (update-weight-parameters 
    (action (string-ascii 24)) 
    (base-weight uint) 
    (multiplier uint) 
    (minimum-threshold uint)
)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-action action) err-invalid-action)
        (asserts! (is-valid-weight base-weight) err-invalid-parameter)
        (asserts! (is-valid-weight multiplier) err-invalid-parameter)
        (asserts! (is-valid-weight minimum-threshold) err-invalid-parameter)
        (ok (map-set contribution-weights 
            {action: action} 
            {
                base-weight: base-weight,
                multiplier: multiplier,
                minimum-threshold: minimum-threshold
            }
        ))
    )
)