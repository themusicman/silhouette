defmodule Fixtures do
  defmodule User do
    defstruct username: "",
              email: "",
              first_name: "",
              last_name: "",
              phone_numbers: [],
              phone_number: nil
  end

  defmodule PhoneNumber do
    defstruct number: ""
  end

  defmodule Film do
    defstruct title: "", director: ""
  end
end
