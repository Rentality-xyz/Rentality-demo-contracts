const { ethers } = require('ethers')

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2,
}

function resolveInterface(contractOrFactory) {
  if (contractOrFactory && contractOrFactory.interface) {
    return contractOrFactory.interface
  }
  throw new Error('Provided value does not expose an interface')
}

function resolveFacetAddress(contractOrFactory, providedAddress) {
  if (providedAddress) return providedAddress
  if (contractOrFactory && contractOrFactory.target) return contractOrFactory.target
  if (contractOrFactory && contractOrFactory.address) return contractOrFactory.address
  throw new Error('Facet address is required')
}

/**
 * Builds a diamond FacetCut object from a deployed contract or a contract factory.
 * @param {*} contractOrFactory ethers contract instance or factory exposing `.interface`
 * @param {{ facetAddress?: string, action?: number }} options optional facet address and action (defaults to Add)
 * @returns {{ facetAddress: string, functionSelectors: string[], action: number }}
 */
function createFacetCut(contractOrFactory, options = {}) {
  const iface = resolveInterface(contractOrFactory)
  const facetAddress = resolveFacetAddress(contractOrFactory, options.facetAddress)
  const functionSelectors = Array.from(
    new Set(
      iface.fragments
        .filter((fragment) => fragment.type === 'function')
        .map((fragment) => {
          const signature = fragment.format('sighash')
          return ethers.id(signature).slice(0, 10)
        })
    )
  )

  return {
    facetAddress,
    functionSelectors,
    action: options.action ?? FacetCutAction.Add,
  }
}

module.exports = {
  createFacetCut,
  FacetCutAction,
}
