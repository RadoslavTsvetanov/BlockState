// Login.js

import { InputForm } from "../../components/form";
import { cookies } from "~/utils/cookies";
import { Api } from "~/utils/api";
import { AuthContext } from "~/utils/context";
import { useContext } from "react";

const Login: React.FC = () => {
  const { token } = useContext(AuthContext);
  const inputSchema = [
    { name: "username", label: "Username", type: "text" },
    { name: "password", label: "Password", type: "password" },
  ];

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100">
      <div className="w-full max-w-md rounded-lg bg-white p-6 shadow-lg">
        <h1 className="mb-6 text-center text-3xl font-semibold">Login</h1>
        <InputForm
          input_schema={inputSchema}
          handleSubmit={async (objToSend: {
            username: string;
            password: string;
          }) => {
            const tokenObj = await Api.login(objToSend);
            cookies.token.set(tokenObj.token);
          }}
        />
        <p className="mt-4 text-center">{console.log(token)}</p>
      </div>
    </div>
  );
};

export default Login;
