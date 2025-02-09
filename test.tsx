import React from 'react'

type Props = {}

const test = (props: Props) => {
  const f = () => { };
  const selfClose = <div />;
  const empty = <div></div>;
  const a = <div>
    text
  </div>;
  const b = <div>
    text
    <div>
      test
    </div>
    text
  </div>;
  return (
    <test>
      123test
      <button onClick={() => {
        return;
      }}>
        bogus
        <div></div>
      </button>
      <button onClick={() => {
        return;
      }} />
      <br />
    </test>
  )

}
