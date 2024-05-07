const bigIntReplacer = (key, value) => {
  if (typeof value === 'bigint') return value.toString()
  return value
}

module.exports = {
  bigIntReplacer,
}
