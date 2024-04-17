// InputForm.js

import React, { useState, ChangeEvent, FormEvent } from "react";

interface InputSchema {
  name: string;
  label: string;
  type: string;
}

interface Props {
  input_schema: InputSchema[];
  handleSubmit: any;
}

export const InputForm: React.FC<Props> = ({ input_schema, handleSubmit }) => {
  const [formData, setFormData] = useState<{ [key: string]: string }>({});

  const handleChange = (e: ChangeEvent<HTMLInputElement>, name: string) => {
    setFormData({
      ...formData,
      [name]: e.target.value,
    });
  };

  return (
    <form
      className="mt-4"
      onSubmit={(e: React.FormEvent) => {
        e.preventDefault();
        handleSubmit(formData);
      }}
    >
      {input_schema.map((input, index) => (
        <div key={index} className="mt-4">
          <label htmlFor={input.name} className="text-gray-700">
            {input.label}:
          </label>
          <input
            type={input.type}
            id={input.name}
            name={input.name}
            value={formData[input.name] ?? ""}
            onChange={(e) => handleChange(e, input.name)}
            className="mt-1 w-full rounded-md border border-gray-400 bg-white px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring focus:ring-blue-200"
          />
        </div>
      ))}
      <button
        type="submit"
        className="mt-4 rounded-md bg-blue-500 px-4 py-2 text-white hover:bg-blue-600 focus:bg-blue-600 focus:outline-none"
      >
        Submit
      </button>
    </form>
  );
};
