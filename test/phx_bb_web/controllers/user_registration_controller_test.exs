defmodule PhxBbWeb.UserRegistrationControllerTest do
  use PhxBbWeb.ConnCase, async: true

  import PhxBb.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()
      name = unique_user()
      user = %{email: email, password: valid_user_password(), username: name, lowercase: name}
      conn = post(conn, Routes.user_registration_path(conn, :create), %{"user" => user})

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ name
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "render errors for invalid email", %{conn: conn} do
      inv_user =
        %{
          "email" => "with spaces",
          "password" => "acceptablepass",
          "username" => "ok_user",
          "lowercase" => "ok_user",
          "post_count" => 0
        }
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => inv_user
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "must have the @ sign and no spaces"
      refute response =~ "should be at least 8 character"
    end

    test "render errors for invalid password", %{conn: conn} do
      inv_user =
        %{
          "email" => "ok_user@example.com",
          "password" => "short",
          "username" => "ok_user",
          "lowercase" => "ok_user",
          "post_count" => 0
        }
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => inv_user
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "should be at least 8 character"
      refute response =~ "must have the @ sign and no spaces"
    end
  end
end
