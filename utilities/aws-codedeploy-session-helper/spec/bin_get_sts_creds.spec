cli = File.join(File.dirname(__FILE__), '../bin/get_sts_creds')

describe "getstscreds cli" do
    it "fails on not providing anything" do
        output = `#{cli} 2>&1`
        expect(output).to include("ArgumentError", "No value")
        expect($?).not_to eq(0)
    end
    it "fails when providing role arn but not session cred file" do
        output = `#{cli} --role-arn arn 2>&1`
        expect(output).to include("ArgumentError", "No value for the fully qualified path that the session")
        expect($?).not_to eq(0)
    end
    it "fails when providing session cred file but not role arn" do
        output = `#{cli} --file file 2>&1`
        expect(output).to include("ArgumentError", "No value for AWS IAM Role")
        expect($?).not_to eq(0)
    end
end
