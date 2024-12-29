;; Title: BTC-Backed NFT Marketplace
;;
;; Summary:
;; A comprehensive NFT marketplace smart contract that enables the creation, trading,
;; and staking of NFTs with BTC collateral backing. The contract supports fractional
;; ownership, staking rewards, and marketplace functionality with protocol fees.
;;
;; Description:
;; This smart contract implements a sophisticated NFT marketplace with the following features:
;; - Minting of NFTs backed by BTC collateral
;; - NFT transfers and marketplace listings
;; - Fractional ownership capabilities
;; - Staking mechanism with yield generation
;; - Protocol fees for marketplace transactions
;; - Built-in safety checks and error handling
;;
;; The contract maintains a minimum collateral ratio of 150% and includes
;; protocol fees of 2.5% on marketplace transactions. Staking rewards are
;; calculated at a 5% annual yield rate.

;; =====================================
;; Constants and Error Codes
;; =====================================

(define-constant contract-owner tx-sender)

;; Error codes for various contract operations
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-token (err u103))
(define-constant err-listing-not-found (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-insufficient-collateral (err u106))
(define-constant err-already-staked (err u107))
(define-constant err-not-staked (err u108))
(define-constant err-invalid-percentage (err u109))
(define-constant err-invalid-uri (err u110))
(define-constant err-invalid-recipient (err u111))
(define-constant err-overflow (err u112))

;; =====================================
;; Data Variables
;; =====================================

;; Protocol parameters
(define-data-var min-collateral-ratio uint u150)  ;; 150% minimum collateral ratio
(define-data-var protocol-fee uint u25)           ;; 2.5% fee in basis points
(define-data-var total-staked uint u0)
(define-data-var yield-rate uint u50)             ;; 5% annual yield rate in basis points
(define-data-var total-supply uint u0)

;; =====================================
;; Data Maps
;; =====================================

;; Main token storage
(define-map tokens
    { token-id: uint }
    {
        owner: principal,
        uri: (string-ascii 256),
        collateral: uint,
        is-staked: bool,
        stake-timestamp: uint,
        fractional-shares: uint
    }
)

;; Marketplace listings
(define-map token-listings
    { token-id: uint }
    {
        price: uint,
        seller: principal,
        active: bool
    }
)

;; Fractional ownership tracking
(define-map fractional-ownership
    { token-id: uint, owner: principal }
    { shares: uint }
)

;; Staking rewards tracking
(define-map staking-rewards
    { token-id: uint }
    { 
        accumulated-yield: uint,
        last-claim: uint
    }
)

;; =====================================
;; Private Helper Functions
;; =====================================

;; Validates URI format and length
(define-private (validate-uri (uri (string-ascii 256)))
    (let
        (
            (uri-len (len uri))
        )
        (and
            (> uri-len u0)
            (<= uri-len u256)
        )
    )
)

;; Ensures recipient is not the contract itself
(define-private (validate-recipient (recipient principal))
    (not (is-eq recipient (as-contract tx-sender)))
)

;; Safe addition with overflow checking
(define-private (safe-add (a uint) (b uint))
    (let
        (
            (sum (+ a b))
        )
        (asserts! (>= sum a) err-overflow)
        (ok sum)
    )
)
